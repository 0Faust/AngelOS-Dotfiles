#!/usr/bin/env python3
"""Report Caps Lock going on and off, for the bar's mark (services/CapsLock).

Prints "on" / "off" once at the start and on every change. niri tells nobody
about lock keys, so this listens to the keyboards' own Caps Lock LED: the
kernel sends an EV_LED event the moment the compositor switches it (needs the
`input` group). Without python-evdev or without access it falls back to
looking at /sys/class/leds a few times a second.

Caps Lock remapped to Escape / Ctrl / layout switch never lights the LED, so
nothing is reported for it.

Privacy: only LED events are looked at; key events are dropped unread, nothing
is stored or logged. Devices are opened read-only and never grabbed.
"""
import fcntl
import glob
import os
import selectors
import struct
import sys
import time

SYSFS = "/sys/class/leds/*::capslock/brightness"
EV_LED = 0x11
LED_CAPSL = 0x01
EVIOCGLED = (2 << 30) | (8 << 16) | (ord("E") << 8) | 0x19
EVENT = struct.Struct("llHHi")


def say(word):
    print(word, flush=True)


class State:
    """Caps Lock over several keyboards: on while any of them shows it."""

    def __init__(self):
        self.leds = {}      # device path -> its LED is lit
        self.last = None    # what was last reported

    def set(self, path, lit):
        self.leds[path] = bool(lit)
        return self.changed()

    def drop(self, path):
        self.leds.pop(path, None)
        return self.changed()

    def changed(self):
        """"on" / "off" when the answer differs from the last one given, else None."""
        now = any(self.leds.values())
        if now == self.last:
            return None
        self.last = now
        return "on" if now else "off"


def sysfs_lit():
    lit = False
    for led in glob.glob(SYSFS):
        try:
            lit = lit or int(open(led).read().strip() or 0) > 0
        except (OSError, ValueError):
            pass
    return lit


def poll(state):
    while True:
        word = state.set("sysfs", sysfs_lit())
        if word:
            say(word)
        time.sleep(0.25)


def has_capslock_led(event_dir):
    try:
        words = open(os.path.join(event_dir, "device/capabilities/led")).read().split()
    except OSError:
        return False
    bits = 0
    for word in words:
        bits = (bits << 64) | int(word, 16)
    return bool((bits >> LED_CAPSL) & 1)


def listen(state):
    selector = selectors.DefaultSelector()
    devices = {}
    last_scan = 0.0

    def drop(path):
        fd = devices.pop(path, None)
        if fd is None:
            return
        try:
            selector.unregister(fd)
        except (KeyError, ValueError):
            pass
        try:
            os.close(fd)
        except OSError:
            pass
        word = state.drop(path)
        if word:
            say(word)

    def rescan():
        seen = set()
        blocked = 0
        for event_dir in glob.glob("/sys/class/input/event*"):
            if not has_capslock_led(event_dir):
                continue
            path = "/dev/input/" + os.path.basename(event_dir)
            seen.add(path)
            if path in devices:
                continue
            try:
                fd = os.open(path, os.O_RDONLY | os.O_NONBLOCK)
            except PermissionError:
                blocked += 1
                continue
            except OSError:
                continue
            try:
                buf = fcntl.ioctl(fd, EVIOCGLED, b"\0" * 8)
                lit = bool(buf[0] & (1 << LED_CAPSL))
            except OSError:
                os.close(fd)
                continue
            devices[path] = fd
            selector.register(fd, selectors.EVENT_READ, data=path)
            word = state.set(path, lit)
            if word:
                say(word)
        for path in list(devices):
            if path not in seen:
                drop(path)
        return blocked and not devices

    while True:
        now = time.monotonic()
        if now - last_scan > 3:
            if rescan():
                return False    # no access to any keyboard: the caller polls instead
            last_scan = now
            if state.last is None:
                say(state.changed() or "off")
        for key, _ in selector.select(timeout=3.0):
            fd = key.fileobj
            path = key.data
            try:
                data = os.read(fd, EVENT.size * 64)
            except OSError:
                drop(path)
                continue
            for off in range(0, len(data) - EVENT.size + 1, EVENT.size):
                _, _, kind, code, value = EVENT.unpack_from(data, off)
                if kind == EV_LED and code == LED_CAPSL:
                    word = state.set(path, value)
                    if word:
                        say(word)


def main():
    state = State()
    listen(state)
    poll(state)


if __name__ == "__main__":
    try:  # go away together with the shell, even on its SIGKILL (stand restarts left copies behind)
        import ctypes
        import signal
        ctypes.CDLL(None).prctl(1, signal.SIGTERM)  # PR_SET_PDEATHSIG
    except (OSError, AttributeError):
        pass
    try:
        main()
    except KeyboardInterrupt:
        pass

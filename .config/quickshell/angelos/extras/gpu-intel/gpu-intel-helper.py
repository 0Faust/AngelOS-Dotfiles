#!/usr/bin/env python3
"""Publish Intel render-engine load from intel_gpu_top, without touching other GPUs."""
import json
import math
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time

STATE = Path('/run/angelos-gpu-intel/state')


def render_load(sample):
    engines = sample.get('engines', {})
    if not isinstance(engines, dict):
        return -1.0
    for name, value in engines.items():
        if ('render' in name.lower() or '3d' in name.lower()) and isinstance(value, dict):
            try:
                busy = float(value['busy'])
                return max(0.0, min(100.0, busy)) if math.isfinite(busy) else -1.0
            except (KeyError, TypeError, ValueError):
                pass
    return -1.0


def publish(load):
    STATE.parent.mkdir(parents=True, exist_ok=True)
    fd, name = tempfile.mkstemp(dir=STATE.parent, prefix='.gpu-')
    try:
        os.fchmod(fd, 0o644)
        with os.fdopen(fd, 'w') as out:
            out.write(f'{load:.1f} {int(time.time())}\n')
        os.replace(name, STATE)
    finally:
        if os.path.exists(name):
            os.unlink(name)


def main():
    # Pick the Intel card explicitly: multi-GPU hosts must not sample the dGPU.
    devices = sorted(Path('/sys/class/drm').glob('card[0-9]*/device'))
    intel = next((p for p in devices if (p / 'vendor').is_file() and (p / 'vendor').read_text().strip() == '0x8086'), None)
    if intel is None:
        raise SystemExit('Intel GPU not found')
    command = ['intel_gpu_top', '-d', 'sys:' + str(intel.resolve()), '-J', '-s', '2000']
    proc = subprocess.Popen(command, stdout=subprocess.PIPE, text=True, bufsize=1)
    decoder = json.JSONDecoder()
    buf = ''
    try:
        publish(-1)
        for line in proc.stdout:
            buf += line
            while True:
                buf = buf.lstrip(' \t\r\n[,')
                if not buf or buf.startswith(']'):
                    if buf.startswith(']'):
                        buf = buf[1:]
                    break
                try:
                    obj, end = decoder.raw_decode(buf)
                except json.JSONDecodeError:
                    break
                buf = buf[end:]
                if isinstance(obj, dict):
                    publish(render_load(obj))
            if len(buf) > 1_000_000:
                raise RuntimeError('intel_gpu_top output is not valid JSON')
    finally:
        proc.terminate()
        proc.wait(timeout=5)
    raise SystemExit(proc.returncode or 1)

if __name__ == '__main__':
    main()

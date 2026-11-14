#!/usr/bin/env python3
"""Report detected GPUs and fresh Intel load without waking discrete GPUs."""
import json
from pathlib import Path
import time


def read_sample(drm=Path('/sys/class/drm'), state=Path('/run/angelos-gpu-intel/state'), now=None):
    cards = []
    for path in drm.glob('card[0-9]*'):
        if not path.name[4:].isdigit():
            continue
        try:
            cards.append((path / 'device/vendor').read_text().strip().lower())
        except OSError:
            continue
    load = -1.0
    try:
        value, timestamp = state.read_text().split()
        value, timestamp = float(value), int(timestamp)
        if 0 <= (time.time() if now is None else now) - timestamp <= 10 and 0 <= value <= 100:
            load = value
    except (OSError, ValueError):
        pass
    return {'intel': '0x8086' in cards, 'count': len(cards), 'load': load}


if __name__ == '__main__':
    while True:
        print(json.dumps(read_sample()), flush=True)
        time.sleep(5)

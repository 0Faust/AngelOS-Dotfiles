#!/usr/bin/env python3
"""Read GPU runtime power from sysfs without invoking nvidia-smi."""
import json
from pathlib import Path


def devices(root=Path('/sys/class/drm')):
    result = []
    vendors = {'0x8086': 'Intel', '0x10de': 'NVIDIA', '0x1002': 'AMD'}
    for card in sorted(root.glob('card[0-9]*')):
        if not card.name[4:].isdigit():
            continue
        dev = card / 'device'
        try:
            vendor = (dev / 'vendor').read_text().strip().lower()
        except OSError:
            continue
        try:
            status = (dev / 'power/runtime_status').read_text().strip()
        except OSError:
            status = 'unknown'
        result.append({'name': vendors.get(vendor, vendor), 'status': status})
    return result

if __name__ == '__main__':
    print(json.dumps(devices()))

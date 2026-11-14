#!/usr/bin/env python3
"""Offline checks for hybrid GPU discovery and stale/invalid samples."""
import importlib.util
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1] / '.config/quickshell/angelos'


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


reader = load('gpu_reader', ROOT / 'scripts/gpu-intel-read.py')
power = load('gpu_power', ROOT / 'scripts/gpu-power-status.py')
helper = load('gpu_helper', ROOT / 'extras/gpu-intel/gpu-intel-helper.py')


class HybridGpuTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.drm = self.root / 'drm'
        self.drm.mkdir()
        for name, vendor, status in [('card0', '0x10de', 'suspended'), ('card1', '0x8086', 'active'), ('card1-eDP-1', '0x8086', 'active')]:
            dev = self.drm / name / 'device'
            (dev / 'power').mkdir(parents=True)
            (dev / 'vendor').write_text(vendor)
            (dev / 'power/runtime_status').write_text(status)
        self.state = self.root / 'state'

    def test_detection_and_stale_samples(self):
        self.assertEqual(reader.read_sample(self.drm, self.state, 100), {'intel': True, 'count': 2, 'load': -1})
        self.state.write_text('36.5 95')
        self.assertEqual(reader.read_sample(self.drm, self.state, 100)['load'], 36.5)
        self.assertEqual(reader.read_sample(self.drm, self.state, 106)['load'], -1)
        self.state.write_text('99 101')
        self.assertEqual(reader.read_sample(self.drm, self.state, 100)['load'], -1)
        self.state.write_text('broken')
        self.assertEqual(reader.read_sample(self.drm, self.state, 100)['load'], -1)

    def test_power_status_does_not_count_connectors(self):
        self.assertEqual(power.devices(self.drm), [{'name': 'NVIDIA', 'status': 'suspended'}, {'name': 'Intel', 'status': 'active'}])

    def test_render_load(self):
        self.assertEqual(helper.render_load({'engines': {'Render/3D/0': {'busy': 27.5}}}), 27.5)
        self.assertEqual(helper.render_load({'engines': {}}), -1)
        self.assertEqual(helper.render_load({'engines': {'Render/3D/0': {'busy': 'invalid'}}}), -1)
        self.assertEqual(helper.render_load({'engines': {'Render/3D/0': {'busy': float('nan')}}}), -1)

if __name__ == '__main__':
    unittest.main()

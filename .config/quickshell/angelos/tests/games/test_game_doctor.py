#!/usr/bin/env python3
"""Game doctor safety checks against a throw-away Steam library.

No real Steam data, game process, cache, or network is touched.
Run: python3 tests/games/test_game_doctor.py
"""
import contextlib
import importlib.util
import io
import json
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("game_doctor", ROOT / "scripts/game-doctor.py")
doctor = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(doctor)


class GameDoctorSafety(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.base = Path(self.tmp.name)
        self.steam = self.base / "Steam"
        self.apps = self.steam / "steamapps"
        self.apps.mkdir(parents=True)
        self._game("42", "Test Game")
        self._game("84", "Other Game")
        doctor.steam_roots = lambda: [self.steam]
        doctor.libraries = lambda: [self.apps]
        doctor.running = lambda _gid: False
        doctor.CACHE = self.base / "cache"

    def tearDown(self):
        self.tmp.cleanup()

    def _game(self, gid, name):
        (self.apps / f"appmanifest_{gid}.acf").write_text(
            f'"AppState" {{\n "appid" "{gid}"\n "name" "{name}"\n}}\n'
        )

    def _call(self, fn, *args):
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            code = fn(*args)
        result = json.loads(output.getvalue())
        self.assertEqual(set(result), {"ok", "ru", "en"})
        self.assertIsInstance(result["ok"], bool)
        self.assertTrue(result["ru"])
        self.assertTrue(result["en"])
        return code, result

    def test_active_game_prefix_reset_is_refused_without_changes(self):
        prefix = self.apps / "compatdata/42/pfx"
        prefix.mkdir(parents=True)
        (prefix / "save.dat").write_bytes(b"save stays intact")
        doctor.running = lambda gid: gid == "42"

        code, result = self._call(doctor.reset_prefix, "42")

        self.assertNotEqual(code, 0)
        self.assertIn("running", result["en"])
        self.assertEqual((prefix / "save.dat").read_bytes(), b"save stays intact")
        self.assertFalse((self.apps / "angelos-prefix-backups").exists())

    def test_closed_game_prefix_is_moved_to_backup_with_contents(self):
        prefix = self.apps / "compatdata/42/pfx"
        prefix.mkdir(parents=True)
        (prefix / "save.dat").write_bytes(b"save stays intact")

        code, result = self._call(doctor.reset_prefix, "42")

        self.assertEqual(code, 0)
        self.assertTrue(result["ok"])
        self.assertFalse(prefix.exists())
        backups = list((self.apps / "angelos-prefix-backups").glob("42-*/pfx/save.dat"))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_bytes(), b"save stays intact")

    def test_shader_cache_is_refused_while_game_runs_then_only_target_is_removed(self):
        cache = self.apps / "shadercache/42"
        other = self.apps / "shadercache/84"
        cache.mkdir(parents=True)
        other.mkdir(parents=True)
        (cache / "compiled.bin").write_bytes(b"target cache")
        (other / "compiled.bin").write_bytes(b"other game cache")
        doctor.running = lambda gid: gid == "42"

        code, result = self._call(doctor.clear_shaders, "42")

        self.assertNotEqual(code, 0)
        self.assertIn("running", result["en"])
        self.assertTrue((cache / "compiled.bin").exists())
        doctor.running = lambda _gid: False
        code, result = self._call(doctor.clear_shaders, "42")
        self.assertEqual(code, 0)
        self.assertTrue(result["ok"])
        self.assertFalse(cache.exists())
        self.assertEqual((other / "compiled.bin").read_bytes(), b"other game cache")


if __name__ == "__main__":
    unittest.main(verbosity=2)

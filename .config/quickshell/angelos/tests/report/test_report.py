#!/usr/bin/env python3
"""The diagnostic archive stays local, is private by default, and scrubs known personal fields.

Runs report.py with a throw-away HOME and no host utilities on PATH.
Run: python3 tests/report/test_report.py
"""
import json
import os
import subprocess
import sys
import tarfile
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts/report.py"


class ReportArchive(unittest.TestCase):
    def test_local_private_scrubbed_archive(self):
        with tempfile.TemporaryDirectory() as d:
            home = Path(d) / "home"
            config = home / ".config"
            fake_bin = Path(d) / "bin"
            config.mkdir(parents=True)
            fake_bin.mkdir()
            (config / "angelos").mkdir()
            (config / "angelos/settings.json").write_text(json.dumps({
                "launcher": {"usage": ["private-app"]},
                "workspaces": {"names": ["private-workspace"]},
                "owner": "private-user",
                "homePath": str(home),
            }))
            env = dict(os.environ, HOME=str(home), USER="private-user", LOGNAME="private-user",
                       LNAME="private-user", USERNAME="private-user", XDG_CONFIG_HOME=str(config),
                       XDG_CACHE_HOME=str(home / ".cache"), PATH=str(fake_bin), LANG="C")
            out = home / "reports"
            run = subprocess.run([sys.executable, str(SCRIPT), "--json", "--out", str(out)],
                                 capture_output=True, text=True, env=env, timeout=30)

            self.assertEqual(run.returncode, 0, run.stderr)
            result = json.loads(run.stdout)
            archive = Path(result["archive"])
            self.assertEqual(archive.parent, out)
            self.assertTrue(archive.is_file())
            self.assertEqual(archive.stat().st_mode & 0o777, 0o600)
            with tarfile.open(archive, "r:gz") as tar:
                files = {Path(member.name).name: tar.extractfile(member).read().decode()
                         for member in tar.getmembers() if member.isfile()}

            self.assertIn("README.txt", files)
            self.assertIn("window or", files["README.txt"])
            self.assertIn("settings.json", files)
            self.assertIn("<1 entries>", files["settings.json"])
            self.assertNotIn("private-app", files["settings.json"])
            self.assertNotIn("private-workspace", files["settings.json"])
            self.assertNotIn("private-user", files["settings.json"])
            self.assertNotIn(str(home), "\n".join(files.values()))
            self.assertTrue(result.get("issue", ""))  # returned only; never opened or submitted


if __name__ == "__main__":
    unittest.main(verbosity=2)

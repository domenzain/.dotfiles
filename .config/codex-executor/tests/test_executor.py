import importlib.machinery
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

SOURCE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(SOURCE))
import runtime

loader = importlib.machinery.SourceFileLoader("executor_setup", str(SOURCE / "setup"))
spec = importlib.util.spec_from_loader(loader.name, loader)
setup = importlib.util.module_from_spec(spec)
loader.exec_module(setup)


class ConfigurationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.config = {"codex_bin": sys.executable, "codex_home": str(self.root),
                       "working_directory": str(self.root), "remote_url": "https://example.invalid/api",
                       "environment_id": "test-authorized-environment"}
        self.path = self.root / "service.local.json"
        self.write()

    def write(self):
        self.path.write_text(json.dumps(self.config))
        self.path.chmod(0o600)

    def test_private_config_and_argument_boundaries(self):
        self.config["environment_id"] = "test environment; $(not-a-command)"
        self.write()
        data = runtime.load_config(self.path)
        self.assertEqual(runtime.command(data)[-1], self.config["environment_id"])

    def test_reject_exposed_config_and_symlink(self):
        self.path.chmod(0o644)
        with self.assertRaises(ValueError): runtime.load_config(self.path)
        self.path.chmod(0o600)
        link = self.root / "link"
        link.symlink_to(self.path)
        with self.assertRaises(ValueError): runtime.load_config(link)

    def test_reject_credentials_and_unknown_fields(self):
        for url in ("http://example.invalid/api", "https://user:pass@example.invalid/api",
                    "https://example.invalid/api?token=x", "https://example.invalid/api#x"):
            self.config["remote_url"] = url; self.write()
            with self.assertRaises(ValueError): runtime.load_config(self.path)
        self.config["remote_url"] = "https://example.invalid/api"
        self.config["token"] = "not-real"; self.write()
        with self.assertRaises(ValueError): runtime.load_config(self.path)

    def test_strip_desktop_lifetime_and_auth_overrides(self):
        with patch.dict(os.environ, {"CODEX_EXEC_SERVER_EXIT_ON_STDIN_CLOSE": "true",
                                    "CODEX_ACCESS_TOKEN": "fake", "DISPLAY": ":99"}):
            env = runtime.environment(self.config)
        self.assertNotIn("CODEX_EXEC_SERVER_EXIT_ON_STDIN_CLOSE", env)
        self.assertNotIn("CODEX_ACCESS_TOKEN", env)
        self.assertNotIn("DISPLAY", env)
        self.assertEqual(env["CODEX_HOME"], self.config["codex_home"])

    def test_detect_duplicate_registration_even_other_binary(self):
        proc = subprocess.Popen([sys.executable, "-c", "import time; time.sleep(30)"],
                                stdout=subprocess.DEVNULL)
        try:
            with patch.object(Path, "iterdir", return_value=[Path('/proc') / str(proc.pid)]), \
                 patch.object(Path, "read_bytes", return_value=b'/other/codex\0exec-server\0--remote\0https://example.invalid/api\0--environment-id\0test-authorized-environment\0'):
                self.assertEqual(setup.unmanaged_matches(self.config, 0), [proc.pid])
                self.assertEqual(setup.unmanaged_matches(self.config, proc.pid), [])
        finally:
            proc.terminate(); proc.wait()

    def test_update_never_restarts_service(self):
        state = self.root / "runtime.json"
        state.write_text(json.dumps({"pid": 123, "binary_sha256": "old"}))
        with patch.object(sys, "argv", ["setup", "--update"]), \
             patch.object(setup, "config_path", return_value=self.path), \
             patch.object(setup, "load_config", return_value=self.config), \
             patch.object(setup, "state_path", return_value=state), \
             patch.object(setup, "main_pid", return_value=123), \
             patch.object(setup, "systemctl") as manager:
            setup.main()
            manager.assert_not_called()


if __name__ == "__main__": unittest.main()

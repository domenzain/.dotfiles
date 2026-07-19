#!/usr/bin/python3

import importlib.machinery
import importlib.util
from pathlib import Path
import stat
import sys
import tempfile
import unittest
from unittest import mock


SCRIPT = Path(__file__).resolve().parents[1] / "lan-dns-sync"
LOADER = importlib.machinery.SourceFileLoader("lan_dns_sync", str(SCRIPT))
SPEC = importlib.util.spec_from_loader(LOADER.name, LOADER)
lan_dns_sync = importlib.util.module_from_spec(SPEC)
sys.modules[LOADER.name] = lan_dns_sync
LOADER.exec_module(lan_dns_sync)


class ValidationTests(unittest.TestCase):
    def test_valid_dual_stack_records(self):
        records = lan_dns_sync.validate_hosts(
            b"192.0.2.10 host.lan.example.invalid\n"
            b"2001:db8::10 host.lan.example.invalid alias.lan.example.invalid\n",
            "lan.example.invalid",
        )
        self.assertEqual(len(records), 3)

    def test_rejects_conflicting_same_family_records(self):
        with self.assertRaisesRegex(lan_dns_sync.SyncError, "conflicting address"):
            lan_dns_sync.validate_hosts(
                b"192.0.2.10 host.lan.example.invalid\n"
                b"192.0.2.11 host.lan.example.invalid\n",
                "lan.example.invalid",
            )

    def test_rejects_empty_out_of_zone_and_uppercase_data(self):
        invalid_candidates = (
            b"# comments are not records\n",
            b"192.0.2.10 public.example.invalid\n",
            b"192.0.2.10 Host.lan.example.invalid\n",
            b"192.0.2.10 host.lan.example.invalid # inline\n",
            b"192.0.2.010 host.lan.example.invalid\n",
        )
        for candidate in invalid_candidates:
            with self.subTest(candidate=candidate):
                with self.assertRaises(lan_dns_sync.SyncError):
                    lan_dns_sync.validate_hosts(candidate, "lan.example.invalid")

    def test_config_must_be_private_and_complete(self):
        with tempfile.TemporaryDirectory() as temporary_dir:
            config_path = Path(temporary_dir) / "sync.local"
            config_path.write_text("LAN_DNS_SYNC_MODE=replica\n", encoding="utf-8")
            config_path.chmod(0o600)
            with self.assertRaisesRegex(lan_dns_sync.SyncError, "missing replica"):
                lan_dns_sync.parse_config(config_path)
            config_path.write_text("LAN_DNS_SYNC_MODE=source\n", encoding="utf-8")
            config_path.chmod(0o644)
            with self.assertRaisesRegex(lan_dns_sync.SyncError, "mode 0600"):
                lan_dns_sync.parse_config(config_path)

    def test_source_config_requires_and_validates_zone(self):
        with tempfile.TemporaryDirectory() as temporary_dir:
            config_path = Path(temporary_dir) / "sync.local"
            config_path.write_text("LAN_DNS_SYNC_MODE=source\n", encoding="utf-8")
            config_path.chmod(0o600)
            with self.assertRaisesRegex(lan_dns_sync.SyncError, "missing source"):
                lan_dns_sync.parse_config(config_path)
            config_path.write_text(
                "LAN_DNS_SYNC_MODE=source\n"
                "LAN_DNS_SYNC_ZONE=lan.example.invalid\n",
                encoding="utf-8",
            )
            self.assertEqual(
                lan_dns_sync.parse_config(config_path)["LAN_DNS_SYNC_ZONE"],
                "lan.example.invalid",
            )


class SynchronizationTests(unittest.TestCase):
    ORIGINAL = b"192.0.2.10 old.lan.example.invalid\n"
    CANDIDATE = b"192.0.2.20 new.lan.example.invalid\n"

    def setUp(self):
        self.temporary_directory = tempfile.TemporaryDirectory()
        root = Path(self.temporary_directory.name)
        self.live = root / "live"
        self.shadow = root / "shadow"
        self.identity = root / "identity"
        self.known_hosts = root / "known-hosts"
        self.lock = root / "lock"
        for path, data in (
            (self.live, self.ORIGINAL),
            (self.shadow, self.ORIGINAL),
            (self.identity, b"private key placeholder\n"),
            (self.known_hosts, b"source.example.invalid ssh-ed25519 placeholder\n"),
        ):
            path.write_bytes(data)
            path.chmod(0o600)
        self.config = {
            "LAN_DNS_SYNC_MODE": "replica",
            "LAN_DNS_SYNC_ZONE": "lan.example.invalid",
            "LAN_DNS_SYNC_SOURCE_HOST": "192.0.2.10",
            "LAN_DNS_SYNC_SOURCE_PORT": "22",
            "LAN_DNS_SYNC_SOURCE_USER": "lan-dns-sync",
            "LAN_DNS_SYNC_IDENTITY_FILE": str(self.identity),
            "LAN_DNS_SYNC_KNOWN_HOSTS_FILE": str(self.known_hosts),
            "LAN_DNS_SYNC_SHADOW_FILE": str(self.shadow),
            "LAN_DNS_SYNC_VERIFY_SERVER": "192.0.2.11",
        }
        self.live_patch = mock.patch.object(lan_dns_sync, "LIVE_FILE", self.live)
        self.lock_patch = mock.patch.object(lan_dns_sync, "LOCK_FILE", self.lock)
        self.root_patch = mock.patch.object(lan_dns_sync.os, "geteuid", return_value=0)
        self.chown_patch = mock.patch.object(lan_dns_sync.os, "fchown")
        for patcher in (self.live_patch, self.lock_patch, self.root_patch, self.chown_patch):
            patcher.start()

    def tearDown(self):
        for patcher in (self.chown_patch, self.root_patch, self.lock_patch, self.live_patch):
            patcher.stop()
        self.temporary_directory.cleanup()

    def test_success_updates_both_files_and_reloads(self):
        reloads = []
        with mock.patch.object(
            lan_dns_sync, "pull_hosts", return_value=self.CANDIDATE
        ), mock.patch.object(
            lan_dns_sync, "systemctl", side_effect=lambda *args: reloads.append(args)
        ), mock.patch.object(lan_dns_sync, "verify_records"):
            changed = lan_dns_sync.synchronize(self.config)

        self.assertTrue(changed)
        self.assertEqual(self.live.read_bytes(), self.CANDIDATE)
        self.assertEqual(self.shadow.read_bytes(), self.CANDIDATE)
        self.assertEqual(reloads, [("reload", "dnsmasq-lan.service")])
        self.assertEqual(stat.S_IMODE(self.shadow.stat().st_mode), 0o600)

    def test_verification_failure_restores_last_good(self):
        reloads = []
        with mock.patch.object(
            lan_dns_sync, "pull_hosts", return_value=self.CANDIDATE
        ), mock.patch.object(
            lan_dns_sync, "systemctl", side_effect=lambda *args: reloads.append(args)
        ), mock.patch.object(
            lan_dns_sync,
            "verify_records",
            side_effect=lan_dns_sync.SyncError("simulated verification failure"),
        ):
            with self.assertRaisesRegex(lan_dns_sync.SyncError, "last-good restored"):
                lan_dns_sync.synchronize(self.config)

        self.assertEqual(self.live.read_bytes(), self.ORIGINAL)
        self.assertEqual(self.shadow.read_bytes(), self.ORIGINAL)
        self.assertEqual(
            reloads,
            [
                ("reload", "dnsmasq-lan.service"),
                ("reload", "dnsmasq-lan.service"),
            ],
        )

    def test_invalid_input_never_touches_last_good(self):
        invalid = b"192.0.2.20 Outside.example.invalid\n"
        with mock.patch.object(
            lan_dns_sync, "pull_hosts", return_value=invalid
        ), mock.patch.object(lan_dns_sync, "systemctl") as systemctl:
            with self.assertRaises(lan_dns_sync.SyncError):
                lan_dns_sync.synchronize(self.config)

        self.assertEqual(self.live.read_bytes(), self.ORIGINAL)
        self.assertEqual(self.shadow.read_bytes(), self.ORIGINAL)
        systemctl.assert_not_called()


if __name__ == "__main__":
    unittest.main()

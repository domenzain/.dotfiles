#!/usr/bin/python3

import configparser
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]


class TailscaleSshUnitTests(unittest.TestCase):
    def test_waits_for_authentication_and_stops_retrying_after_success(self):
        parser = configparser.ConfigParser(interpolation=None)
        parser.read(ROOT / "lan-dns-tailscale-ssh.service", encoding="utf-8")

        self.assertIn("tailscaled.service", parser["Unit"]["Wants"])
        self.assertIn("tailscaled.service", parser["Unit"]["After"])
        self.assertEqual(parser["Unit"]["StartLimitIntervalSec"], "0")
        self.assertEqual(parser["Service"]["Type"], "oneshot")
        self.assertEqual(
            parser["Service"]["ExecStartPre"], "/usr/bin/tailscale ip -4"
        )
        self.assertEqual(
            parser["Service"]["ExecStart"], "/usr/bin/tailscale set --ssh"
        )
        self.assertEqual(parser["Service"]["RemainAfterExit"], "yes")
        self.assertEqual(parser["Service"]["Restart"], "on-failure")
        self.assertEqual(parser["Install"]["WantedBy"], "multi-user.target")


if __name__ == "__main__":
    unittest.main()

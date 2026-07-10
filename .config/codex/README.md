# Codex remote-control service

These files make the standalone Codex app-server available as an optional
`systemd --user` service on a headless Linux host. The service is deliberately
not enabled by a dotfiles checkout or new-box installation.

Install or update the standalone CLI and register the units:

```sh
"$HOME/.config/codex/setup" --install-only
```

After logging in with ChatGPT, opt in to the always-on service:

```sh
"$HOME/.codex/packages/standalone/current/bin/codex" login
"$HOME/.config/codex/setup" --enable
```

The setup command is idempotent and also supports:

```sh
"$HOME/.config/codex/setup" --update
"$HOME/.config/codex/setup" --restart
"$HOME/.config/codex/setup" --status
"$HOME/.config/codex/setup" --disable
```

## Ownership and updates

The service always runs the official standalone binary at
`~/.codex/packages/standalone/current/bin/codex`. Do not bootstrap Codex's detached
app-server daemon or run a second copy from npm, tmux, or another systemd unit;
all of them contend for the same Unix control socket.

`codex-binary.path` watches the standalone `current` path. An update performed
by `setup --update` or the official installer restarts the service only when it
is already running. A failed download leaves the existing service untouched.

The service launcher uses a deterministic PATH because systemd does not load
shell startup files. Add host-specific paths with a systemd override that sets
`CODEX_SERVICE_PATH`; do not edit the tracked launcher.

For boot-time availability without an interactive login, enable lingering:

```sh
loginctl enable-linger "$USER"
```

After an update, `setup --status` should show one standalone CLI version and an
active service. Verify remote availability with a real session rather than
relying on process state alone.

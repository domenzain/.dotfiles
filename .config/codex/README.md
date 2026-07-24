# Codex remote-control service

The tracked systemd unit and launchd plist are inert templates. Install and
start the definition for the current host explicitly:

```sh
"$HOME/.config/codex/setup" --enable
```

Install the standalone CLI without installing a service:

```sh
"$HOME/.config/codex/setup" --install-only
```

The helper also supports `--update`, `--restart`, `--status`, and `--disable`.
Linux uses a generated link under `~/.config/systemd/user`; macOS uses a
generated mode-600 plist under `~/Library/LaunchAgents`. Disabling unloads and
removes only that generated definition.

The service runs the official standalone app-server on its Unix control socket.
It uses `SIGHUP` for graceful restarts: Codex stops accepting
shutdown-sensitive work, waits for every running assistant turn to finish,
exits, and the service manager starts the newly installed binary. The hourly
updater can therefore apply a release without terminating an active task.

The launcher uses a deterministic PATH because user service managers do not
load shell startup files. Set `CODEX_SERVICE_PATH` in the service environment
for machine-specific additions; do not edit the tracked launcher or templates.

The shared hourly updater is managed by
`~/.config/agent-services/setup`.

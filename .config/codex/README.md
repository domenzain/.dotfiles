# Codex remote-control service

The tracked unit is a template outside systemd's live search path. It is linked
into `~/.config/systemd/user` only by an explicit service setup:

```sh
"$HOME/.config/codex/setup" --enable
```

Install the standalone CLI without installing a service:

```sh
"$HOME/.config/codex/setup" --install-only
```

The helper also supports `--update`, `--restart`, `--status`, and `--disable`.
`--disable` removes the live unit link while preserving the tracked template.

The service runs the official standalone app-server on its Unix control socket.
It uses `SIGHUP` for graceful restarts: Codex stops accepting shutdown-sensitive
work, waits for every running assistant turn to finish, exits, and systemd starts
the newly installed binary. The hourly updater can therefore apply a release
without terminating an active task.

The launcher uses a deterministic PATH because systemd does not load shell
startup files. Add machine-specific paths with a systemd override that sets
`CODEX_SERVICE_PATH`; do not edit the tracked launcher or unit template.

The shared hourly timer is managed by `~/.config/agent-services/setup`.

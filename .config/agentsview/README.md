# AgentsView service

The launcher sources an untracked `service.local`; generated application state
and tokens remain under `~/.agentsview` and are never copied into dotfiles.

On Linux, the tracked unit is a template outside systemd's live search path.
The explicit opt-in initializes safe loopback defaults, links the template, and
starts the observer:

```sh
"$HOME/.config/agentsview/setup" --enable
```

The helper also supports `--init-only`, `--update`, `--restart`, `--status`, and
`--disable`. `--disable` removes the systemd link but preserves private config.
The existing LaunchAgent path remains available on macOS.

The shared hourly updater checks for a new release before changing anything.
When an update exists, it stops the systemd observer, removes any stale
unmanaged background daemon, runs AgentsView's built-in updater, and restores
the systemd service even when installation fails. AgentsView only reads and
indexes agent sessions; it does not own or terminate Codex or Grok tasks.

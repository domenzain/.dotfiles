# AgentsView service

The launcher sources an untracked `service.local`; generated application state
and tokens remain under `~/.agentsview` and are never copied into dotfiles.

The tracked systemd unit and launchd plist are inert templates. The explicit
opt-in initializes safe loopback defaults, installs the definition for the
host service manager, and starts the observer:

```sh
"$HOME/.config/agentsview/setup" --enable
```

On Linux the live definition is a symlink under `~/.config/systemd/user`; on
macOS it is a generated mode-600 copy under `~/Library/LaunchAgents`. The helper
also supports `--init-only`, `--update`, `--restart`, `--status`, and
`--disable`. Disabling unloads and removes only the generated definition while
preserving `service.local`.

The shared hourly updater checks for a new release before changing anything.
When an update exists, it stops the supervised observer, removes any stale
unmanaged background daemon, runs AgentsView's built-in updater, and restores
the service even when installation fails. AgentsView only reads and indexes
agent sessions; it does not own or terminate Codex or Grok tasks.

# Agent services

This directory coordinates the Codex, Grok, and AgentsView user services. A
dotfiles checkout contains only inert systemd unit and launchd plist templates.
Explicitly opt in with:

```sh
"$HOME/.config/agent-services/setup" --enable
```

On Linux, the setup links systemd user units and enables the persistent hourly
timer with up to five minutes of jitter. On macOS, it copies generated
LaunchAgents into `~/Library/LaunchAgents` and loads an updater immediately and
every hour. Both paths serialize checks through one stable per-user lock,
using `flock` on Linux or the stock `lockf` utility on macOS.

A failed provider check does not prevent the other tools from checking; the
next hour retries failures. Each tool owns its safe-apply policy: Codex drains
active turns on `SIGHUP`, Grok restarts only while its active-session registry
is locked and idle, and AgentsView restarts only its observer. There are no
immediate path-triggered restarts. `setup --disable` unloads generated service
definitions while preserving every untracked host-local configuration file.

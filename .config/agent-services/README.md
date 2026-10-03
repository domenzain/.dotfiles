# Agent services

This directory coordinates the Codex, Grok, and AgentsView user services plus
the Pi and Oh My Pi command-line tools. A dotfiles checkout contains only inert
systemd unit and launchd plist templates.
Explicitly opt in with:

```sh
"$HOME/.config/agent-services/setup" --enable
```

On Linux, the setup links systemd user units and enables the persistent hourly
timer with up to five minutes of jitter. On macOS, it copies generated
LaunchAgents into `~/Library/LaunchAgents` and loads an updater immediately and
every hour. Both paths install Pi and Oh My Pi when absent, then include their
built-in `pi update --self` and `omp update` commands in the same serialized
hourly check. The check uses `flock` on Linux or the stock `lockf` utility on
macOS.

A failed component check does not prevent the other tools from checking; the
next hour retries failures. Pi and Oh My Pi update directly through their own
CLIs; the Oh My Pi web installer is used only for an absent first install. Each
long-running service owns its safe-apply policy: Codex drains active turns on
`SIGHUP`, Grok restarts only while its active-session registry is locked and
idle, and AgentsView restarts only its observer. There are no immediate
path-triggered restarts. `setup --disable` unloads generated service definitions
while preserving installed CLIs and every untracked host-local configuration
file.

The optional Linux dot executor is separately enabled with
`~/.config/codex-executor/setup --enable` after a bounded handover from an
already authorized executor. Generic `--enable` does not enroll or start it.
Status and disable include it when installed. Hourly updates compare its
configured binary after the Codex update and report a pending controlled
restart; exec-server has no documented app-server-style turn-drain API, so the
updater never signals it automatically. See `../codex-executor/README.md`.

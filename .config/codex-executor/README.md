# Standalone dot executor (experimental, Linux)

This optional service supervises an **already authorized** dot environment using
the public `codex exec-server --remote ... --environment-id ...` interface. It is
separate from the Codex Remote app-server. It does not enroll a computer, grant
access, copy credentials, or run the desktop app. Replacing a desktop-owned dot
executor is experimental; OpenAI's dot documentation still requires the app.

Copy `service.local.example.json` to the ignored `service.local.json`, set mode
0600, and replace every placeholder with your existing nonsecret registration
metadata and normal signed-in profile path. Do not put tokens or credentials in
this file. Obtain the endpoint and environment ID from the already authorized
executor; do not guess or create another grant. Python 3 and an installed Codex
CLI with `exec-server` support are prerequisites.

`setup --check` validates configuration, normal login, and duplicate executors.
`setup --enable` is a separate explicit opt-in. First arrange an independent,
bounded recovery, stop the old executor, then enable this service. Never register
two executors for the same environment concurrently. Verify a fresh dot task
and its process ancestry after the handover before cancelling recovery.

`setup --status`, `--restart`, `--disable`, and `--update` match the other service
helpers. An explicit restart/stop interrupts local work. There is no documented
turn-drain/idle API for exec-server: **do not send it app-server's SIGHUP**.
The shared updater installs Codex through the existing Codex helper, then this
helper compares the configured binary with the running snapshot. It reports
pending changes but never restarts an active executor automatically. Apply them
with an approved idle `setup --restart`. Crash recovery starts the installed
binary after five seconds, with five starts per minute limiting failure loops.
After fixing a start-limit failure, use `systemctl --user reset-failed
codex-executor.service` and an explicit start.

Linux uses the existing systemd user-unit symlink convention, mode-077 umask,
and the user journal (`journalctl --user -u codex-executor.service`). Registration
metadata stays in private config; upstream runtime logs may contain operational
metadata, so inspect them locally and redact before sharing. Launch state is
private under `${XDG_STATE_HOME:-~/.local/state}/codex-executor`.
`disable` removes only the generated service link and preserves private config
and sign-in. Existing user lingering provides startup without an interactive
login; the helper never enables lingering itself. Reboot survival must be tested
separately. This does not persist the temporary Xvfb session or depend on it.

macOS is intentionally rejected until a launchd lifecycle can be tested. Other
agent services retain their existing cross-platform support.

While this service owns the registration, do not also start the desktop app's
executor for the same environment. A GUI fallback requires first disabling or
stopping this service to avoid duplicate registration.

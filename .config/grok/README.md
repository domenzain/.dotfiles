# Grok agent service

`setup --install-only` installs the official stable Grok CLI without installing
a service. `setup --enable` is the explicit service opt-in: it creates an
untracked mode-600 `service.local`, generates a stable authentication secret,
links the tracked unit template into systemd, and starts the loopback server.

```sh
"$HOME/.config/grok/setup" --install-only
"$HOME/.config/grok/setup" --enable
```

The helper also supports `--update`, `--restart`, `--status`, and `--disable`.
No model, agent, prompt, permission, or tool configuration is managed here.

The supervised service disables Grok's internal auto-updater. The shared
hourly updater checks `grok update --check --json`, takes Grok's own active
session lock, and validates registered PIDs. It stops/restarts the service only
while the registry is idle; otherwise it defers to the next hour. The lock is
held through service stop so a new task cannot enter between the check and the
signal.

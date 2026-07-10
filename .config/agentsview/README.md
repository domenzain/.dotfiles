# AgentsView service

The tracked `service` launcher deliberately sources an untracked
`service.local`, following the same public/private convention as
`.gitconfig` and `.gitlocal`.

After checking out these dotfiles on a new host:

```sh
"$HOME/.config/agentsview/setup" --init-only
"${EDITOR:-vi}" "$HOME/.config/agentsview/service.local"
"$HOME/.config/agentsview/setup"
```

`setup` is idempotent. It never overwrites an existing `service.local`, always
restores its mode to `600`, and converges the platform service state. It is safe
for an installer or agent to run again after changing host-specific settings.

Keep `service.local` and `~/.agentsview/config.toml` out of the public
repository. The latter is AgentsView's application config and may contain
`auth_token`, `remote_hosts`, and remote-sync tokens.

For a custom collector/source topology, let AgentsView create
`~/.agentsview/config.toml` once, preserve its generated `auth_token` and
`cursor_secret`, and add the private `remote_hosts` entries in place. Do not
copy one host's generated config to another host. Rerun `setup` after changing
either private config so the supervised daemon reloads it.

## What setup does on Linux

The systemd user units expect the AgentsView binary at
`~/.local/bin/agentsview` unless `AGENTSVIEW_BIN` overrides it.

It reloads the systemd user manager, enables both units, restarts
`agentsview.service`, and starts `agentsview-binary.path`. These operations are
safe to repeat and apply changes from `service.local` immediately.

On a headless host, enable lingering so the user service starts at boot and
survives logout:

```sh
loginctl enable-linger "$USER"
```

## What setup does on macOS

It replaces an already loaded `io.agentsview.service` job and bootstraps the
tracked LaunchAgent again, so rerunning setup also reloads plist changes.

The LaunchAgent and systemd service both use the same portable launcher and
the same private `service.local` contract.

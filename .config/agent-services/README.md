# Agent services

This directory coordinates the Codex, Grok, and AgentsView user services. A
dotfiles checkout contains only inert unit templates. Explicitly opt in with:

```sh
"$HOME/.config/agent-services/setup" --enable
```

That command enables the three services and one persistent hourly timer. The
timer adds up to five minutes of jitter and serializes checks with a single
lock. A failed provider check does not prevent the other tools from checking;
the next hour retries failures.

Each tool owns its safe-apply policy: Codex drains active turns on `SIGHUP`,
Grok restarts only while its active-session registry is locked and idle, and
AgentsView restarts only its observer. There are no immediate path-triggered
restarts.

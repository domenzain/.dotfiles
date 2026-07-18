# Split-horizon DNS for `lan.domenza.in`

This helper installs a dedicated dnsmasq instance on Debian/Ubuntu hosts. It
answers the private `lan.domenza.in` namespace on the LAN and on Tailscale,
while forwarding all other questions to a per-host LAN upstream.

It deliberately uses `dnsmasq-base`, a separate systemd unit, interface-scoped
binding, and no loopback listener. That lets it coexist with systemd-resolved
and libvirt dnsmasq instances. `bind-dynamic` makes Tailscale restarts and
address changes safe.

## Install or update

```sh
"$HOME/.config/lan-dns/setup" --init-only
"${EDITOR:-vi}" "$HOME/.config/lan-dns/node.local"
"${EDITOR:-vi}" "$HOME/.config/lan-dns/hosts.local"
"$HOME/.config/lan-dns/setup"
```

`setup` is idempotent and preserves the untracked, mode-`0600` `node.local`
and `hosts.local`. Actual addresses, hostnames, interfaces, and upstreams belong
only in those ignored local files.
It validates dnsmasq and systemd configuration before installation, refuses an
active stock `dnsmasq.service`, restarts only when files changed, and verifies
authoritative UDP and TCP answers through every active LAN/Tailscale address.

The new-box gist exposes the same operation as an explicit `--lan-dns` or
`INSTALL_LAN_DNS=1` opt-in. On a small resolver VM, run this helper directly;
the full workstation bootstrap is unnecessary.

## Resilient topology

Run byte-identical private `hosts.local` files on both resolver nodes. DHCP and
Tailscale clients do not reliably preserve primary/secondary order, so treat
the pair as active-active. Advertise both reserved LAN addresses through DHCP
and add both Tailscale addresses as restricted nameservers for the private
zone, enabling “Use with exit node” for each. If records return LAN addresses,
both nodes must also advertise the same Tailscale subnet route so DNS failover
preserves reachability.

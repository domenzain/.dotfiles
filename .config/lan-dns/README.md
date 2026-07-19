# Split-horizon DNS for `lan.domenza.in`

This helper installs a dedicated dnsmasq instance on Debian/Ubuntu hosts. It
answers the private `lan.domenza.in` namespace on the LAN and on Tailscale,
while forwarding all other questions to a per-host LAN upstream.

It deliberately uses `dnsmasq-base`, a separate systemd unit, interface-scoped
binding, and no loopback listener. That lets it coexist with systemd-resolved
and libvirt dnsmasq instances. `bind-dynamic` makes Tailscale restarts and
address changes safe.

The helper also installs a narrow nftables IPv6 input guard. DNS arriving on
the selected LAN interface is accepted only from link-local addresses and
directly connected IPv6 prefixes on that interface; TCP and UDP port 53 from
off-link IPv6 sources are dropped. The prefixes are discovered from routes
without a next-hop, including `proto ra` routes, so no site address is tracked.
Traffic arriving on `tailscale0` and all IPv4 traffic are unchanged.

`LAN_DNS_RESTRICT_SSH_IPV6=1` in the ignored `node.local` optionally applies
the same source boundary to TCP port 22 arriving on the LAN interface. It is
validated as `0` or `1` and defaults to `0`, so generic resolver nodes and
existing installs do not change SSH policy; Tailscale SSH remains unaffected.

The guard owns only the dedicated `ip6 lan_dns_guard` table. It does not enable
the distribution `nftables.service`, flush the full ruleset, or modify tables
owned by Tailscale, libvirt, UFW, or firewalld. A systemd oneshot must succeed
before dnsmasq starts; a timer atomically refreshes the table about once a
minute for IPv6 renumbering and to repair an external ruleset reload. Routed
IPv6 VLANs are intentionally not treated as same-LAN clients. This narrow
guard complements rather than replaces a host or edge firewall.

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
active stock `dnsmasq.service`, applies the IPv6 guard before starting DNS,
restarts only when files changed, and verifies authoritative UDP and TCP
answers through every active LAN/Tailscale address. If the guard cannot be
applied, setup stops the dedicated DNS unit instead of leaving port 53 exposed.

The new-box gist exposes the same operation as an explicit `--lan-dns` or
`INSTALL_LAN_DNS=1` opt-in. On a small resolver VM, run this helper directly;
the full workstation bootstrap is unnecessary.

## Resilient topology

DHCP and Tailscale clients do not reliably preserve primary/secondary order, so
treat the resolver pair as active-active. Advertise both reserved LAN addresses
through DHCP and add both Tailscale addresses as restricted nameservers for the
private zone, enabling “Use with exit node” for each. If records return LAN
addresses, both nodes must also advertise the same Tailscale subnet route so
DNS failover preserves reachability.

The optional replication helper keeps the active-active resolvers on the same
record set without making DNS availability depend on the source. One curated
source owns `hosts.local`; a replica pulls the source's live
`/etc/dnsmasq-lan.hosts` over pinned, key-only SSH about once a minute. If the
source, SSH, validation, reload, or verification fails, the replica continues
serving its last-good file and the timer tries again later.

Replication is deliberately inert unless the ignored, mode-`0600`
`sync.local` exists. Start from `sync.local.example` and select one role:

- `LAN_DNS_SYNC_MODE=source` plus `LAN_DNS_SYNC_ZONE` validates the curated
  source file and installs the root-owned `lan-dns-export` helper.
- `LAN_DNS_SYNC_MODE=replica` additionally installs and enables the pull
  service and timer. All replica keys shown in the example are required.

On the source, authorize a dedicated replica public key with an OpenSSH forced
command. The account needs no sudo access because the exported live file is
readable; the helper itself is installed root-owned:

```text
restrict,command="/usr/local/libexec/lan-dns-export" ssh-ed25519 REPLICA_PUBLIC_KEY
```

The replica's identity file must be inaccessible to group and others. Its
`known_hosts` file must contain a host key verified out of band; setup never
uses `ssh-keyscan` or accepts a new host key. Configure the source by an address
that does not depend on the private DNS being synchronized. The verification
server must likewise be a literal address on the replica itself.

The puller accepts at most 64 KiB of ASCII hosts data. Every non-comment line
must contain a canonical IP address followed by one or more lowercase FQDNs at
or below `LAN_DNS_SYNC_ZONE`. It rejects empty files, inline comments,
non-canonical addresses, out-of-zone names, and two different addresses of the
same family for one name. A name may validly have both an IPv4 and IPv6 record.

After validation, the puller compares the candidate with both the live file and
the configured user `hosts.local` shadow. It preserves their ownership and
modes while replacing changed files atomically, reloads dnsmasq with SIGHUP,
and queries every A/AAAA record directly through the configured replica server.
Any failed update restores both previous files and reloads the last-good data.
Setup and the timer use the same `flock`, so an update cannot race a setup run.

All addresses, usernames, record data, key paths, and pinned-host paths stay in
ignored local files. Only generic programs, units, and documentation belong in
the public repository.

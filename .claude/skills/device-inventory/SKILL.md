---
name: device-inventory
description: The Device inventory board on Nextcloud Deck (every physical device at home and the summer house, its ownership level, options and decision) and how to answer "any progress on <device>?" or "anything new since last time?". Use when the user asks about a device's ownership, open firmware, what it leaks, or wants the inventory updated or re-checked.
---

# Device inventory

One Deck board, **Device inventory**, read and written with the `deck` CLI (conventions in the `deck` skill). One card per physical device that has firmware with a network interface or a cloud account behind it; identical units share a card. Peripherals without firmware or network are not cards.

## Stacks: the ownership ladder

A card moves right as ownership increases. The stack is the *current state*, the decision is on the card.

| Stack | Meaning |
|---|---|
| `Unassessed` | seeded, no research or decision yet |
| `Vendor` | vendor firmware and vendor cloud, no local control; we know what it leaks |
| `Contained` | vendor firmware, but locally controlled and/or cloud blocked (DNS filter, no account, local API) |
| `Open` | open firmware or OS we control, not Nix (OpenWrt, Valetudo, /e/OS, Prusa firmware) |
| `Nix` | built from nix-home |

Labels: `home` / `summer` (site), `confirm` (model or detail unverified), `replace` (decision: replace with an ownable device), `watch` (an upstream effort exists that can change the options), `op` (operator work), `repo` (work in nix-home).

## Card template

Every description has these fields in this order, so re-checks are mechanical:

```
**What:** model, where it sits, what it does for us
**Address:** LAN IP / MAC / tailnet name
**Talks to:** vendor endpoints or "local only"; what data leaves
**Today:** stack and why
**Options:**
1. Nix: ...
2. Open firmware/OS: ...
3. Contain: ...
4. Replace: ...
**Decision:** none | option N, date, one line why
**Watch:** 2–4 lines, each a URL or project plus what to look for
**Last checked:** YYYY-MM-DD
```

## Answering "any progress on X?" / "anything new since last time?"

1. `deck board "Device inventory"`, then `deck card <id>` for the device asked about; for a general question, every card with the `watch` label.
2. For each **Watch** line, search the web (extended mode) for what changed after **Last checked**: new releases, new supported models, a project going dormant, a vendor policy change.
3. If something changed: `deck comment <id>` with the date and what changed; update the Options and Watch lines with `deck edit <id> -d -` (read first, the PUT replaces the whole description); if an option became real, move the card (`deck move` + comment) and say so to the user. If the decision should change, propose it, do not change it.
4. Always update **Last checked** in the description. Do not comment when nothing changed.
5. Report in a short list: device, changed or unchanged, one line each.

## Adding or changing a device

- New device named in conversation or seen on the LAN (`ip neigh` on controller, mDNS, SSDP): add a card in `Unassessed` with `confirm`, research it, fill the template, move it to its ladder stack with a comment.
- Model found or decision taken: edit the card, drop `confirm`, comment the date.
- A device that leaves the house: comment, `deck archive`.
- A device that becomes a nix-home host also gets its `hosts/<name>` entry; the card points at it.

## Identifying unknown LAN devices

From a host on that LAN: `ip neigh` (MACs), `resolvectl query <ip>` (DHCP hostname via the router), `avahi-browse -a -t -r -p` (mDNS), an SSDP M-SEARCH (UPnP model names), `curl https://api.macvendors.com/<oui>`. Controller sees the most neighbours because it is the LAN's DNS.

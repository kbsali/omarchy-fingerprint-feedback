# 0002. Listen to fprintd on the system bus with dbus-monitor

Date: 2026-11-19

Status: accepted

## Context

`pam_fprintd` gives no on-screen sign when a finger unlocks `sudo` in a
terminal. fprintd logs nothing on a match either, so the journal is no source.
fprintd 1.94 broadcasts `net.reactivated.Fprint.Device.VerifyStatus` with no
destination, so any user on the system bus can receive it. The signal was
captured live on 2026-11-19 (`verify-match` on 2 `sudo` runs).

A first version ran the same listener as a systemd user service calling
`omarchy osd`. It worked, but needed 2 files outside the plugin system and could
not drive a bar widget.

## Decision

Run `dbus-monitor` as a `Process` inside the plugin's `service` entry point,
matching on fprintd's well-known name, and call the `omarchy-osd` CLI on each
result. Third-party plugins may not summon `omarchy.osd` directly.

## Consequences

- Install and removal go through `omarchy plugin`; nothing else to set up.
- One `dbus-monitor` process lives as long as the shell; it is restarted 5 s
  after an exit.
- The match rule follows fprintd across its bus activations, as observed.
- Depends on fprintd keeping the signal broadcast; a unicast change upstream
  would silence the plugin.

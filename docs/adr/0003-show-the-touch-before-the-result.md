# 0003. Show the touch before the result

Date: 2026-11-26

Status: accepted

## Context

With only `VerifyStatus` to go on, the OSD appeared once fprintd had decided.
Until then the user could not tell whether the sensor had seen the finger, and
a scan the sensor could not read (`verify-retry-scan` and siblings) showed
nothing at all.

fprintd 1.94 exposes a `finger-present` property that emits
`PropertiesChanged`, broadcast like `VerifyStatus`. Captured live on
2026-11-26 on a Synaptics 06cb:00f9 sensor: `finger-present` turns `true`
about 0.4 s before `verify-match`.

## Decision

Add a second match rule to the same `dbus-monitor` for `PropertiesChanged` from
fprintd. On `finger-present` `true`, show "Reading fingerprint…" in the OSD and
the bar; the result replaces it. Map the 4 retry statuses to "Scan failed, try
again".

## Consequences

- Feedback starts at the touch on any sensor whose libfprint driver reports
  finger status. On a driver that does not, the plugin behaves as before.
- `dbus-monitor` prints `PropertiesChanged` over several lines, so the parser
  keeps 1 bit of state between lines.
- The service now also sees `finger-needed` changes; it ignores them.

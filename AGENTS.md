# Agent instructions

Omarchy shell plugin (QML, Quickshell). Read `docs/adr/` first: it records why
the plugin is built the way it is.

- `manifest.json` follows the Omarchy plugin manifest schema. Check it with
  `omarchy plugin validate "$PWD"`.
- Third-party plugins cannot summon `omarchy.osd` directly; call the
  `omarchy-osd` CLI.
- Never edit `/usr/share/omarchy/`: read it for reference only.
- Test on a live system: link this folder to
  `~/.config/omarchy/plugins/kbsali.fingerprint-feedback`, then run
  `sudo -k; sudo true` and touch the sensor.

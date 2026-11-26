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
  `sudo -k; sudo true` and touch the sensor. A change to the
  `dbus-monitor` command needs `omarchy restart shell`: the hot reload
  keeps the running process with its old arguments.
- Open work lives in `TODO.md`.
- Releases: `manifest.json` `version` always equals the latest git tag
  without its `v`. To release, bump `version` in the PR that ships the
  change; after the squash merge, tag the merge commit
  (`git tag --annotate vX.Y.Z --message vX.Y.Z`), push the tag, then
  `gh release create vX.Y.Z --generate-notes --verify-tag`.

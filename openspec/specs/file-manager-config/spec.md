# file-manager-config Spec
Yazi file manager: keymaps, theme, plugins.

## Requirements
- **R1** (MUST): Track `yazi.toml`, `keymap.toml`, `theme.toml` under `~/.config/yazi/`.
- **R2** (MAY): Track `package.toml` if plugins used.

## Scenarios
- **S1**: GIVEN apply runs — WHEN `yazi` launched — THEN tracked keymaps, theme, settings.
- **S2**: GIVEN plugin in package.toml — WHEN synced — THEN installable via `ya pack -i`.
- **S3**: GIVEN no package.toml — WHEN yazi starts — THEN no plugin errors.

# shell-config Spec
Fish shell config.fish, PATH, CachyOS integration.

## Requirements
- **R1** (MUST): Track `~/.config/fish/config.fish`. Exclude `fish_variables`.
- **R2** (SHOULD): Include `~/.local/bin` and CachyOS paths in fish PATH.
- **R3** (MUST): `fish -n config.fish` exits zero before apply.

## Scenarios
- **S1**: GIVEN fresh init — WHEN `chezmoi add ~/.config/fish/config.fish` — THEN tracked.
- **S2**: GIVEN `fish_variables` exists — WHEN `chezmoi add` — THEN not added.
- **S3**: GIVEN valid config.fish — WHEN `fish -n` — THEN exit 0.
- **S4**: GIVEN syntax error — WHEN `fish -n` — THEN non-zero, apply blocked.

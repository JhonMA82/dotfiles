# terminal-config Spec
Ghostty and Alacritty configs: fonts, themes, keybindings.

## Requirements
- **R1** (MUST): Track `~/.config/ghostty/config` (font, theme, keybindings).
- **R2** (MUST): Track `~/.config/alacritty/alacritty.toml` + theme.
- **R3** (MAY): Template font if availability differs per machine.

## Scenarios
- **S1**: GIVEN apply runs — WHEN Ghostty opens — THEN tracked font, theme, keybindings.
- **S2**: GIVEN apply runs — WHEN Alacritty opens — THEN tracked config + theme.
- **S3**: GIVEN font absent — WHEN terminal starts — THEN falls back to monospace.

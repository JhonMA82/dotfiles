---
name: cfg-niri
description: "Trigger: niri, compositor, outputs, binds, window-rules, animaciones, gaps, layout, monitores, pantallas, niri config, wayland tiling. Manage Niri compositor config — outputs, bindings, window rules, animations, and validation."
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## Activation Contract

Load this skill when the user asks to change niri configuration — outputs (monitors), keyboard binds, window rules, animations, gaps/layout, or any `niri` keyword. Follow the READ→PLAN→APPLY→VALIDATE→VERSIONAR pipeline from `cfg-common.md`.

## Hard Rules

- ALWAYS read `AGENTS.md` before suggesting GPU-intensive settings. Intel Broadwell-U: NO heavy animations, prefer low `stiffness`/`damping-ratio` springs, keep durations short (≤200ms).
- Niri config is **KDL format** — NOT TOML, NOT YAML. Blocks use `{ }`, key=value pairs, `//` comments. `/=` prefixes comment out blocks. Preserve structure and comments.
- DMS auto-generates files in `dms/` (colors.kdl, layout.kdl, alttab.kdl, binds.kdl, outputs.kdl, cursor.kdl). NEVER edit these. They are included via `include "dms/..."` lines. If user wants to change DMS-managed settings, tell them to use the DMS GUI instead.
- Multi-machine: use chezmoi Go templates (`{{ if eq .chezmoi.hostname "cachyos-x8664" }}` for laptop, `{{ else if eq .chezmoi.hostname "desktop" }}` for desktop PC). Template data lives in `.chezmoi.yaml.tmpl` or is auto-detected.
- ALWAYS run `niri validate` after edits. If niri is not the active compositor (no `$WAYLAND_DISPLAY` pointing to niri), warn but still run validation — it checks syntax, not runtime.
- Delegate all chezmoi operations to `cfg-chezmoi`. Never run `chezmoi` commands directly.
- Commit message format: `type(niri): {description}`.

## Decision Gates

| Situation | Action |
|-----------|--------|
| User requests output/monitor change | READ → PLAN (mode, scale, position, VRR) → APPLY → VALIDATE → VERSIONAR |
| User requests keybinding/bind change | READ current binds → PLAN (modifier+key=action) → APPLY → VALIDATE → VERSIONAR |
| User requests window rule | READ current rules → PLAN (match app-id/title, properties) → APPLY → VALIDATE → VERSIONAR |
| User requests animation change | READ AGENTS.md first → PLAN (check GPU for heavy springs) → APPLY → VALIDATE → VERSIONAR |
| User requests gaps/layout change | READ current layout → PLAN → APPLY → VALIDATE → VERSIONAR |
| Edit touches a `dms/` file | BLOCK. "DMS files are auto-generated. Use the DMS GUI to change this setting." |
| GPU-intensive animation (blur, high stiffness) | Warn: Broadwell GPU is underpowered. Suggest lighter alternatives (opacity instead of blur, lower stiffness values, shorter durations). Ask confirmation. |
| Template syntax error in `{{ if }}` blocks | BLOCK. Show the specific line with the syntax error. |
| `niri validate` fails | BLOCK commit. Show validation output. |
| File not in chezmoi source | Delegate first-add to `cfg-chezmoi` |

## Execution Steps

### READ

1. Locate niri config in chezmoi source: `~/.local/share/chezmoi/dot_config/niri/config.kdl`
2. Read full config content
3. Read `AGENTS.md` for hardware constraints (GPU, RAM, display)
4. Identify DMS includes: `dms/colors.kdl`, `dms/layout.kdl`, `dms/alttab.kdl`, `dms/binds.kdl`, `dms/outputs.kdl`, `dms/cursor.kdl`
5. Return current state: outputs, binds, window-rules, animations, hardware context

### PLAN — Output Change

Outputs control monitor resolution, position, scale, and variable refresh rate. The built-in laptop monitor is usually `"eDP-1"`. Use `niri msg outputs` to discover active output names. KDL syntax:

```
output "eDP-1" {
    mode "1366x768@60"
    position x=0 y=0
    variable-refresh-rate
}
```

For multi-machine (laptop vs desktop), wrap in chezmoi templates:

```
{{ if eq .chezmoi.hostname "cachyos-x8664" }}
output "eDP-1" {
    mode "1366x768@60"
    position x=0 y=0
}
{{ else if eq .chezmoi.hostname "desktop" }}
output "HDMI-A-1" {
    mode "1920x1080@60"
    position x=0 y=0
}
{{ end }}
```

```text
# Current: output block is commented out with /-
# Plan: activate laptop output eDP-1 at native resolution
# Hardware check: Intel HD Graphics Broadwell — 1366x768 is safe
```

### PLAN — Bind Change

Niri keybindings use modifier+key syntax. The config typically lives in `dms/binds.kdl` (DMS-managed), but user-defined binds can be added directly in `config.kdl`. If the user wants to override a DMS binding, they MUST add it to `config.kdl` after the DMS include lines (config.kdl overrides DMS).

Keybinding syntax in KDL:

```
binds {
    Mod+Q { close-window; }
    Mod+Shift+Return { spawn "foot"; }
}
```

Modifiers: `Mod` (Super/Win), `Ctrl`, `Alt`, `Shift`. Combine with `+`.

```text
# Plan: add Mod+Return to spawn terminal
# Append to config.kdl: Mod+Return { spawn "ghostty"; }
```

### PLAN — Window Rule Change

Window rules match apps by `app-id` (regex) or `title` (regex) and apply properties. Properties include: `open-floating`, `default-column-width`, `draw-border-with-background`, `geometry-corner-radius`, `clip-to-geometry`, `open-on-workspace`, `block-out-from`.

```
window-rule {
    match app-id=r#"^org\.example\.App$"#
    open-floating true
    default-column-width { proportion 0.5; }
}
```

```text
# Plan: add floating rule for new app
# Append window-rule block matching the app-id
```

### PLAN — Animation Change

Niri supports spring-based and duration-based animations. **Hardware constraint**: Intel Broadwell-U GPU — avoid high stiffness values (>1000), prefer short durations (≤200ms), and use `ease-out-` curves which are lighter to compute.

Supported animation types:
- `workspace-switch` — spring-based
- `window-open` / `window-close` — duration+curve
- `horizontal-view-movement` — spring-based
- `window-movement` / `window-resize` — spring-based
- `config-notification-open-close` — spring-based
- `screenshot-ui-open` — duration+curve
- `overview-open-close` — spring-based

```text
# Current: window-open duration-ms 150 curve "ease-out-expo"
# Plan: slow down to 200ms for a smoother feel
# Hardware check: 200ms is safe for Broadwell
```

### PLAN — Gaps/Layout Change

Layout controls gaps, background color, column centering, focus ring border, and shadows.

```text
# Plan: change border active-color to "#ff0000"
# Edit: layout > border > active-color "#ff0000"
```

### APPLY

Edit `~/.local/share/chezmoi/dot_config/niri/config.kdl`:
- For outputs: add/edit `output "name" { mode "..."; position x=... y=...; }` blocks
- For binds: append a `binds { ... }` block after the DMS include lines (to override DMS)
- For window rules: append a new `window-rule { ... }` block
- For animations: modify values inside the `animations { ... }` block
- For layout: modify values inside the `layout { ... }` block
- Preserve all other lines, comments, blank lines, and whitespace
- NEVER edit `include "dms/..."` lines or any DMS-managed file

### VALIDATE

```bash
# Validate syntax (works even if niri is not the active compositor):
niri validate

# Alternative: validate a specific file
niri validate ~/.local/share/chezmoi/dot_config/niri/config.kdl
```

- Exit code 0 → pass, continue to VERSIONAR
- Exit code non-zero → fail, BLOCK commit, show error output
- If `niri` binary not found: "WARNING: niri binary not found — cannot validate config syntax. Showing diff for manual review:"

### VERSIONAR

Delegate to `cfg-chezmoi`:
- `chezmoi re-add` the config file
- `git commit -m "feat(niri): {description}"`
- Return commit hash and diff to user

## Output Contract

Return to `cfg` orchestrator:
- Domain: `niri`
- Action performed: `output`, `bind`, `window-rule`, `animation`, `gaps`, `layout`, etc.
- Changed lines (before→after)
- Validation result: `pass` or `fail` or `skipped (niri binary not found)`
- Commit hash (or "not committed" if validation failed)

## References

- `_shared/cfg-common.md` — pipeline contract
- `cfg-chezmoi/SKILL.md` — chezmoi operations
- `~/.config/niri/config.kdl` — real config on disk (symlinked by chezmoi)
- `~/.local/share/chezmoi/dot_config/niri/config.kdl` — chezmoi source copy
- Context7: `/YaLTeR/niri` — KDL config syntax, action reference, window rule syntax
- `AGENTS.md` — hardware constraints (Broadwell GPU, 3.7 GiB RAM, Niri Wayland, DMS)
- `openspec/specs/niri-config/spec.md` — niri spec with hostname-template requirements

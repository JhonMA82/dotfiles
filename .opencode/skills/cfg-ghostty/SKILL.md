---
name: cfg-ghostty
description: "Trigger: ghostty, terminal, theme, font, plugin, keybinding, opacity, padding, cursor, background-blur. Manage Ghostty terminal config — themes, fonts, keybindings, and validation."
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## Activation Contract

Load this skill when the user asks to change ghostty configuration — theme, font, keybindings, appearance, or any `ghostty` keyword. Follow the READ→PLAN→APPLY→VALIDATE→CONFIRM→VERSIONAR pipeline from `cfg-common.md`.

## Hard Rules

- ALWAYS read `AGENTS.md` before suggesting GPU-intensive settings. Intel Broadwell-U: NO `background-blur`, prefer `background-opacity`.
- ALWAYS run `ghostty +validate-config` after edits. If in TTY (no `$WAYLAND_DISPLAY`), warn + show diff — do NOT block.
- NEVER commit without human confirmation. `ghostty +validate-config` only checks syntax, not visual behavior. After VALIDATE passes, ask the user to test the change in Ghostty and confirm it works before committing.
- Preserve existing comments and structure when editing the config. Only change the target line.
- Delegate all chezmoi operations to `cfg-chezmoi`. Never run `chezmoi` commands directly.
- Commit message format: `type(ghostty): {description}`.

## Decision Gates

| Situation | Action |
|-----------|--------|
| User requests theme change | READ → PLAN (parse theme value) → APPLY (update `theme =`) → VALIDATE → CONFIRM → VERSIONAR |
| User requests font change | READ AGENTS.md first → PLAN (check GPU for blur) → APPLY (update `font-family =`, `font-size =`) → VALIDATE → CONFIRM → VERSIONAR |
| User requests keybinding | READ current keybinds → PLAN (modifier+key=action) → APPLY (append/edit `keybind =`) → VALIDATE → CONFIRM → VERSIONAR |
| User requests shader install | READ → PLAN (shader path + config entry) → APPLY (write `.glsl` file + edit config) → VALIDATE (syntax) → CONFIRM → VERSIONAR |
| User requests plugin install | Ghostty has no plugin system (as of 2026). Report to user. |
| GPU-intensive feature (blur) | Warn: Broadwell GPU does not support background blur. Suggest opacity. Ask confirmation. |
| File not in chezmoi source | Delegate first-add to `cfg-chezmoi` |

## Execution Steps

### READ

1. Locate ghostty config in chezmoi source: `~/.local/share/chezmoi/dot_config/ghostty/config`
2. Read full config content
3. Read `AGENTS.md` for hardware constraints (GPU, RAM, display)
4. Return current state: all key-value pairs, hardware context

### PLAN — Theme Change

Determine new theme value from user request. Valid themes include built-in themes and custom palette themes like `catppuccin-mocha`, `tokyo-night`, `dankcolors`.

```text
# Current: theme = dankcolors
# Plan: theme = catppuccin-mocha
# Edit: replace "dankcolors" with "catppuccin-mocha" on the theme = line
```

### PLAN — Font Change

Check AGENTS.md before suggesting font sizes. This machine has a laptop display — suggest conservative sizes (11–14). Font family MUST be a valid system font path or family name.

```text
# Current: font-size = 12, no explicit font-family
# Plan: font-family = "JetBrainsMono Nerd Font", font-size = 14
# Hardware check: Broadwell GPU → no blur, opacity OK
```

### PLAN — Keybinding Modification

Ghostty keybinding syntax: `keybind = modifier+key=action`. Supported modifiers: `ctrl`, `shift`, `alt`, `super`. Multiple modifiers joined with `+`. Use `physical:` prefix for non-US keyboard layouts. Actions are Ghostty actions (e.g., `new_window`, `new_tab`, `close_surface`, `increase_font_size:1`).

```text
# Append new keybinding:
# keybind = ctrl+shift+t=new_tab
```

### APPLY

Edit `~/.local/share/chezmoi/dot_config/ghostty/config`:
- For theme: replace the value on the `theme =` line
- For font: update/add `font-family =` and `font-size =` lines
- For keybinding: append a new `keybind =` line or update an existing one
- Preserve all other lines, comments, blank lines, and whitespace

### VALIDATE

```bash
# If $WAYLAND_DISPLAY or $DISPLAY is set:
ghostty +validate-config

# If in TTY (no display server):
echo "WARNING: no display server — cannot validate ghostty config"
echo "Showing diff for manual review:"
chezmoi diff
```

- Exit code 0 → pass, continue to CONFIRM
- Exit code non-zero → fail, BLOCK commit, show error output

### CONFIRM

**MANDATORY for ALL changes.** `ghostty +validate-config` only checks config syntax — it does NOT verify shaders compile, themes look right, fonts render correctly, or keybindings work.

1. After VALIDATE passes, STOP and tell the user: "Config validated. Testealo en Ghostty y confirmame si funciona como esperás."
2. Do NOT commit or push until the user explicitly confirms the change works.
3. If the user reports the change doesn't work, go back to APPLY with the fix. Do NOT start a new commit chain — amend the staged changes instead.
4. Only proceed to VERSIONAR after the user says it works.

### VERSIONAR

**Only run after user confirms the change works.** Delegate to `cfg-chezmoi`:
- `chezmoi re-add` the config file
- `git commit -m "feat(ghostty): {description}"`
- Return commit hash and diff to user

## Plugins / Future

Ghostty currently has **no plugin system**. When user requests plugin installation, respond:
"Ghostty does not support plugins yet. Configuration is file-based via `~/.config/ghostty/config`. If this changes in a future release, we can add plugin workflows then."

## Output Contract

Return to `cfg` orchestrator:
- Domain: `ghostty`
- Action performed: `theme`, `font`, `keybinding`, etc.
- Changed lines (before→after)
- Validation result: `pass` or `fail` or `skipped (TTY)`
- Commit hash (or "not committed" if validation failed)

## References

- `_shared/cfg-common.md` — pipeline contract
- `cfg-chezmoi/SKILL.md` — chezmoi operations
- `~/.config/ghostty/config` — real config on disk
- `~/.local/share/chezmoi/dot_config/ghostty/config` — chezmoi source copy
- Context7: `/ghostty-org/ghostty` — current keybinding syntax and config reference
- `AGENTS.md` — hardware constraints (Broadwell GPU, 3.7 GiB RAM, Niri Wayland)

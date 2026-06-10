---
name: cfg-yazi
description: "Trigger: yazi, file manager, opener, glow, keymap, theme, preview, markdown, md. Manage Yazi file manager config — openers, keybindings, themes, and plugin rules."
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## Activation Contract

Load this skill when the user asks to change yazi configuration — openers, keybindings, themes, preview rules, or any `yazi` keyword. Follow the READ→PLAN→APPLY→VALIDATE→VERSIONAR pipeline from `cfg-common.md`.

## Hard Rules

- ALWAYS read `AGENTS.md` for RAM constraints. 3.7 GiB total — do NOT increase `image_alloc` or spawn heavy previewers (e.g., full-image renderers) without user confirmation.
- Yazi has no formal validation command. Manual check: TOML syntax is valid, `yazi --version` confirms binary works.
- Preserve existing comments and structure when editing TOML configs. Only change the target section/line.
- Delegate all chezmoi operations to `cfg-chezmoi`. Never run `chezmoi` commands directly.
- Commit message format: `type(yazi): {description}`.
- Tracked configs: `yazi.toml`, `keymap.toml`, `theme.toml`. Exclude `flavors/`, `plugins/`, `init.lua`, `package.toml`, `LICENSE`, `README.md` — these are re-fetched via package manager (`ya pack -i`).

## Decision Gates

| Situation | Action |
|-----------|--------|
| User requests opener change (e.g., glow for .md) | READ → PLAN (parse opener rule) → APPLY (add to `[opener]` section) → VALIDATE → VERSIONAR |
| User requests keybinding | READ current keybinds → PLAN (on=key, run=action) → APPLY (append/edit `[[mgr.prepend_keymap]]`) → VALIDATE → VERSIONAR |
| User requests theme change | READ current theme → PLAN (update `theme.toml` flavor) → APPLY → VALIDATE → VERSIONAR |
| User requests plugin install | Plugins are managed via `package.toml` + `ya pack -i`. Note: `package.toml` is NOT tracked in chezmoi. Guide user to add to `package.toml` manually, then run `ya pack -i`. |
| File not in chezmoi source | Delegate first-add to `cfg-chezmoi` |
| RAM-heavy change requested (image_alloc, previewer) | Warn: machine has 3.7 GiB RAM. Request confirmation before increasing. |

## Execution Steps

### READ

1. Locate yazi configs in chezmoi source: `~/.local/share/chezmoi/dot_config/yazi/yazi.toml`, `keymap.toml`, `theme.toml`
2. Read full config contents
3. Read `AGENTS.md` for hardware constraints (RAM)
4. Return current state: all opener rules, keybindings, theme settings, hardware context

### PLAN — Opener Change

Yazi opener syntax uses `[opener]` section with named opener arrays. Each entry has: `run` (command), optional `block` (bool), optional `for` (glob pattern), optional `desc` (string).

```toml
[opener]
edit = [
  { run = 'nvim "$@"', block = true },
  { run = 'glow "$@"', block = true, for = "*.md", desc = "View markdown with glow" },
]

play = [
  { run = 'mpv "$@"', orphan = true, for = "unix" },
]
```

Openers are routed via `[open]` rules section using `use = "opener_name"`. The `for` filter on an opener entry limits it to matching files; the first matching entry in order wins.

```text
# Current: edit opener only has nvim
# Plan: add glow entry before nvim for *.md files
# Edit: insert { run = 'glow "$@"', block = true, for = "*.md", desc = "View markdown with glow" } before nvim entry
```

### PLAN — Keybinding

Yazi keybinding syntax: `[[mgr.prepend_keymap]]` with `on` (key) and `run` (command or plugin action). Multiple keys can be an array: `on = ["<C-e>"]`.

```toml
[[mgr.prepend_keymap]]
on   = "l"
run  = "plugin smart-enter"
desc = "Enter the child directory, or open the file"
```

### PLAN — Theme Change

Theme is set in `theme.toml` via `[flavor]` section:

```toml
[flavor]
dark = "dracula"
```

To change theme, update the `dark` or `light` value. Flavors are installed via package manager (`ya pack -i`). Ensure the flavor is listed in `package.toml` (not tracked in chezmoi).

### APPLY

Edit `~/.local/share/chezmoi/dot_config/yazi/yazi.toml` (or `keymap.toml`, `theme.toml`):
- For opener: add entry to the relevant opener array in `[opener]` section
- For keybinding: append a new `[[mgr.prepend_keymap]]` block or edit an existing one
- For theme: update the `dark` or `light` value in `[flavor]` section of `theme.toml`
- Preserve all other lines, comments, blank lines, and whitespace

### VALIDATE

```bash
# Yazi has no formal validation command. Run manual checks:
# 1. Confirm TOML is parseable (no invalid syntax)
yazi --version  # confirms binary is functional

# 2. Visual inspection of diff
chezmoi diff
```

- `yazi --version` succeeds → pass, continue to VERSIONAR
- If yazi binary is absent → warn, show diff for manual review

### VERSIONAR

Delegate to `cfg-chezmoi`:
- `chezmoi re-add` the modified config file(s)
- `git commit -m "feat(yazi): {description}"`
- Return commit hash and diff to user

## Plugins

Yazi plugins are managed via `package.toml` and installed with `ya pack -i`. Since `package.toml`, `plugins/`, `flavors/`, and `init.lua` are excluded from chezmoi tracking (they are re-fetched), plugin install workflows are:
1. User adds `[[plugin.deps]]` entry to `~/.config/yazi/package.toml`
2. User runs `ya pack -i` to install
3. `cfg-yazi` does NOT track these files — this is intentional to avoid versioning large binary/blob directories

## Output Contract

Return to `cfg` orchestrator:
- Domain: `yazi`
- Action performed: `opener`, `keybinding`, `theme`, etc.
- Changed lines (before→after)
- Validation result: `pass` or `fail` or `skipped (no yazi binary)`
- Commit hash (or "not committed" if validation failed)

## References

- `_shared/cfg-common.md` — pipeline contract
- `cfg-chezmoi/SKILL.md` — chezmoi operations
- `~/.config/yazi/yazi.toml` — real config on disk
- `~/.config/yazi/keymap.toml` — current keybindings
- `~/.config/yazi/theme.toml` — theme/flavor config
- `~/.local/share/chezmoi/dot_config/yazi/` — chezmoi source copies
- Context7: `/yazi-rs/yazi` — opener syntax, keybinding reference, and configuration docs
- `AGENTS.md` — hardware constraints (3.7 GiB RAM)

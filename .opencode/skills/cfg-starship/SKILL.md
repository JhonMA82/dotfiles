---
name: cfg-starship
description: "Trigger: starship, prompt, starship theme, starship preset, starship module, starship config. Manage Starship cross-shell prompt — themes, presets, modules, format, and shell integration."
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## Activation Contract

Load this skill when the user asks to change starship configuration — prompt format, themes, presets, modules (directory, git_branch, etc.), symbols, shell integration, or any `starship` keyword. Follow the READ→PLAN→APPLY→VALIDATE→CONFIRM→VERSIONAR pipeline.

## Hard Rules

- Config file: `~/.config/starship.toml` (TOML format). Chezmoi source: `dot_config/starship.toml`.
- Starship is a **cross-shell prompt** — not fish-specific. Shell integration hooks live in each shell's config, not in starship.toml.
- Presets are downloaded TOML files from https://starship.rs/presets/ — applied as the full config replacement.
- Preserve existing comments and TOML structure. Only change the target key/section.
- Delegate all chezmoi operations to `cfg-chezmoi`. Never run `chezmoi` commands directly.
- Commit message format: `feat(starship): {description}`.
- **NEVER commit without human confirmation.** Validate TOML syntax, then ask user to test the prompt before committing.

## Decision Gates

| Situation | Action |
|-----------|--------|
| User requests theme/preset change | READ → PLAN (download preset or set palette) → APPLY → VALIDATE → CONFIRM → VERSIONAR |
| User requests module config | READ → PLAN (edit [module] section) → APPLY → VALIDATE → CONFIRM → VERSIONAR |
| User requests format change | READ → PLAN (edit top-level `format` key) → APPLY → VALIDATE → CONFIRM → VERSIONAR |
| User requests symbol change | READ → PLAN (edit module's `symbol` key) → APPLY → VALIDATE → CONFIRM → VERSIONAR |
| Starship not installed | BLOCK. Offer to install: `sudo pacman -S starship` |
| Shell integration missing | BLOCK. Starship needs `eval "$(starship init {shell})"` in shell config. Delegate to `cfg-fish` for fish init. |
| File not in chezmoi source | Delegate first-add to `cfg-chezmoi` |
| User wants to disable a module | Set module's `disabled = true` in its `[module]` section |

## Execution Steps

### READ

1. Locate starship config: `~/.config/starship.toml`
2. Read full config content.
3. Check if starship is installed: `starship --version`
4. Return current state: active modules, format string, palette if set.

### PLAN — Theme / Preset

Starship has built-in presets available at https://starship.rs/presets/. Applying a preset means replacing the entire `starship.toml` with the downloaded preset file.

```
Plan for "nerd-font" preset:
  Download: curl -sS https://starship.rs/presets/toml/nerd-font-symbols.toml
  Apply to ~/.config/starship.toml
```

Custom themes use the `[palettes]` section:
```toml
[palettes.custom]
blue = "#458588"
green = "#98971a"
red = "#cc241d"
```

### PLAN — Module Config

Each module has its own `[module_name]` section. Common modules:
- `[directory]` — current path display
- `[git_branch]` — git branch name
- `[git_status]` — git dirty/staged indicators
- `[git_commit]` — commit hash
- `[git_state]` — rebase/merge state
- `[nodejs]`, `[python]`, `[rust]`, `[go]` — language versions
- `[package]` — package.json version
- `[username]`, `[hostname]` — user/host display
- `[time]` — timestamp
- `[character]` — the prompt character (❯)
- `[status]`, `[cmd_duration]` — exit code, duration

```toml
[directory]
style = "bold blue"
truncation_length = 3
truncate_to_repo = true
format = "[$path]($style) "
```

### PLAN — Format Change

Top-level `format` controls the overall prompt layout:
```toml
format = "$username$directory$git_branch$character "
```

### PLAN — Disable a Module

```toml
[package]
disabled = true
```

### APPLY

Edit `~/.config/starship.toml`:
- For presets: replace entire file with downloaded preset TOML.
- For module changes: add or modify the `[module]` section.
- For format changes: edit the top-level `format` key.
- Preserve all other sections, comments, blank lines, and whitespace.

### VALIDATE

```bash
# Starship has no --validate flag, but `explain` parses the config:
starship explain 2>&1
```

- Exit code 0 + valid output → pass, continue to CONFIRM
- Exit code non-zero → fail, highlight error
- If `starship` binary not found: "WARNING: starship not installed — cannot validate config. Showing diff for manual review:"

Manual TOML validation checks:
- All section headers use `[name]` syntax
- Values match expected types (string, bool, int)
- No duplicate keys or malformed arrays

### CONFIRM

**MANDATORY.** TOML validation is only syntactic; it does NOT verify the prompt looks correct.

1. After VALIDATE passes, STOP and tell the user: "Config validada. Abrí una terminal nueva y fijate cómo se ve el prompt. Confirmame si está como esperás."
2. Do NOT commit or push until the user explicitly confirms.
3. If the user reports issues, go back to APPLY with the fix. Do NOT start a new commit chain.
4. Only proceed to VERSIONAR after the user says it works.

### VERSIONAR

**Only run after user confirms the change works.** Delegate to `cfg-chezmoi`:
- `chezmoi re-add` the config file
- `git commit -m "feat(starship): {description}"`
- Return commit hash and diff to user

## Key Config Reference

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `format` | string | `$all` | Top-level prompt format string |
| `right_format` | string | `""` | Right-aligned prompt content |
| `continuation_prompt` | string | `"▶▶" ` | Prompt for continued lines |
| `scan_timeout` | int | `30` | Timeout for module scans (ms) |
| `command_timeout` | int | `500` | Timeout for command execution (ms) |
| `add_newline` | bool | `true` | Add newline before prompt |
| `palette` | string | `""` | Preset palette name |

### Module Common Keys

Every module supports these keys unless stated otherwise:

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `format` | string | varies | Module format string with `$variables` |
| `style` | string | `""` | Style string (bold, dim, color, bg:color) |
| `disabled` | bool | `false` | Disable this module entirely |
| `symbol` | string | varies | Module symbol (e.g., `""` for git_branch) |
| `detect_extensions` | array | varies | File extensions that trigger this module |
| `detect_files` | array | varies | Files that trigger this module |
| `detect_folders` | array | varies | Folders that trigger this module |

## Shell Integration

Starship requires an init hook in each shell. For fish, the hook goes in `~/.config/fish/config.fish`:

```fish
# Starship prompt
if command -v starship > /dev/null
    starship init fish | source
end
```

This is managed by `cfg-fish`, not `cfg-starship`. If the user needs the init hook added, delegate to `cfg-fish`.

## Presets

Available presets (downloadable TOML files):
- Nerd Font Symbols: `curl -sS https://starship.rs/presets/toml/nerd-font-symbols.toml`
- No Nerd Font: `curl -sS https://starship.rs/presets/toml/no-nerd-font.toml`
- Bracketed Segments: `curl -sS https://starship.rs/presets/toml/bracketed-segments.toml`
- Pure: `curl -sS https://starship.rs/presets/toml/pure-preset.toml`
- Gruvbox Rainbow: `curl -sS https://starship.rs/presets/toml/gruvbox-rainbow.toml`
- Jetpack: `curl -sS https://starship.rs/presets/toml/jetpack.toml`

Full list: https://starship.rs/presets/

## Output Contract

Return to `cfg` orchestrator:
- Domain: `starship`
- Action performed: `theme`, `preset`, `module`, `format`, `symbol`, `disable_module`, `shell_init`
- Changed keys (before→after)
- Validation result: `pass` or `fail`
- Commit hash (or "not committed" if validation failed or user didn't confirm)

## References

- `_shared/cfg-common.md` — pipeline contract
- `cfg-chezmoi/SKILL.md` — chezmoi operations
- `cfg-fish/SKILL.md` — fish shell init hook
- `~/.config/starship.toml` — real config on disk
- Docs: https://starship.rs/config/
- Presets: https://starship.rs/presets/
- `AGENTS.md` — hardware constraints

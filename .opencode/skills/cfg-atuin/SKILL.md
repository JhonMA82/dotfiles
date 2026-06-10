---
name: cfg-atuin
description: "Trigger: atuin, shell history, sync, search mode, daemon, theme, stats, history filter. Manage Atuin shell history config — search mode, sync, daemon, stats, theme, and UI settings."
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## Activation Contract

Load this skill when the user asks to change atuin configuration — search mode, sync, daemon, theme, stats, history filters, UI columns, or any `atuin` keyword. Follow the READ→PLAN→APPLY→VALIDATE→CONFIRM→VERSIONAR pipeline.

## Hard Rules

- Config file: `~/.config/atuin/config.toml` (TOML format). Chezmoi source: `dot_config/atuin/config.toml`.
- **NEVER track `~/.local/share/atuin/`** — contains history.db, encryption keys, auth sessions (private data).
- **NEVER track `~/.atuin/`** — contains binaries and logs.
- Fish integration (`~/.config/fish/conf.d/atuin.env.fish`) is handled by `cfg-fish`, not this skill.
- Preserve existing comments and TOML structure. Only change the target key/section.
- Delegate all chezmoi operations to `cfg-chezmoi`. Never run `chezmoi` commands directly.
- Commit message format: `type(atuin): {description}`.
- **NEVER commit without human confirmation.** Validate TOML syntax, then ask the user to test the change in the shell before committing.

## Decision Gates

| Situation | Action |
|-----------|--------|
| User requests search mode change | READ → PLAN (valid modes: prefix, fulltext, fuzzy, daemon-fuzzy, skim) → APPLY → VALIDATE → CONFIRM → VERSIONAR |
| User requests sync setup/change | READ → PLAN (sync_address, sync_frequency, auto_sync, sync.records) → APPLY → VALIDATE → CONFIRM → VERSIONAR |
| User requests daemon config | READ → PLAN (enabled, autostart, sync_frequency, socket_path) → APPLY → VALIDATE → CONFIRM → VERSIONAR |
| User requests theme change | READ → PLAN (name: default, autumn, marine, or custom) → APPLY → VALIDATE → CONFIRM → VERSIONAR |
| User requests UI change | READ → PLAN (columns, style, inline_height, invert, etc.) → APPLY → VALIDATE → CONFIRM → VERSIONAR |
| User requests stats config | READ → PLAN (common_subcommands, common_prefix) → APPLY → VALIDATE → CONFIRM → VERSIONAR |
| User requests history filter | READ → PLAN (history_filter, cwd_filter, secrets_filter) → APPLY → VALIDATE → CONFIRM → VERSIONAR |
| File not in chezmoi source | Delegate first-add to `cfg-chezmoi` |

## Execution Steps

### READ

1. Locate atuin config: `~/.config/atuin/config.toml`
2. Read full config content.
3. Return current state: active keys and their values.

### PLAN — Search Mode

Valid modes: `prefix`, `fulltext`, `fuzzy`, `daemon-fuzzy`, `skim`.

If setting `daemon-fuzzy`, ensure daemon section is also configured:
```toml
search_mode = "daemon-fuzzy"

[daemon]
enabled = true
autostart = true
```

### PLAN — Sync

Sync v2 is enabled with `[sync] records = true`. Main sync config lives at top level:
```toml
sync_address = "https://api.atuin.sh"
sync_frequency = "1h"
auto_sync = true
```

### PLAN — Theme

Built-in themes: `default`, `autumn`, `marine`. Custom themes go in `~/.config/atuin/themes/`.
```toml
[theme]
name = "autumn"
```

### PLAN — UI Columns

Default columns: `["duration", "time", "command"]`. Available types: duration, time, datetime, directory, host, user, exit, command.
```toml
[ui]
columns = ["duration", "time", "directory", "command"]
```

### PLAN — History Filter

Regex-based filters for commands and directories:
```toml
history_filter = ["^secret-cmd"]
cwd_filter = ["^/very/secret/directory"]
secrets_filter = true
```

### APPLY

Edit `~/.config/atuin/config.toml`:
- For simple key-value: replace or add the line.
- For TOML sections: add or modify the `[section]` block.
- Preserve all other lines, comments, blank lines, and whitespace.

### VALIDATE

Check TOML syntax is valid (no missing brackets, valid keys). Atuin has no `--validate-config` flag, so validate manually:
- TOML sections use `[section]` format
- Values match documented types (string, bool, int, array)
- No duplicate keys or malformed arrays

### CONFIRM

**MANDATORY.** TOML validation is only syntactic; it does NOT verify atuin actually reads the config correctly.

1. After VALIDATE passes, STOP and tell the user: "Config validada. Probala en la shell (ctrl-r o flecha arriba) y confirmame si funciona como esperás."
2. Do NOT commit or push until the user explicitly confirms the change works.
3. If the user reports the change doesn't work, go back to APPLY with the fix. Do NOT start a new commit chain.
4. Only proceed to VERSIONAR after the user says it works.

### VERSIONAR

**Only run after user confirms the change works.** Delegate to `cfg-chezmoi`:
- `chezmoi re-add` the config file
- `git commit -m "feat(atuin): {description}"`
- Return commit hash and diff to user

## Key Config Reference

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `search_mode` | string | `fuzzy` | prefix, fulltext, fuzzy, daemon-fuzzy, skim |
| `filter_mode` | string | `global` | global, host, session, directory, workspace |
| `enter_accept` | bool | `false` | Enter executes immediately vs requiring tab |
| `style` | string | `compact` | auto, full, compact |
| `inline_height` | int | `40` | Max lines for TUI (0 = full screen) |
| `auto_sync` | bool | `true` | Automatically sync when logged in |
| `sync_frequency` | string | `1h` | How often to sync |
| `sync_address` | string | `https://api.atuin.sh` | Sync server URL |
| `history_filter` | array | `[]` | Regex patterns to exclude |
| `secrets_filter` | bool | `true` | Filter out known secret patterns |

## Data Directories (DO NOT TRACK)

- `~/.local/share/atuin/` — history.db, encryption key, auth sessions. **PRIVATE.**
- `~/.atuin/` — binaries (`atuin`, `atuin-update`), logs. **INSTALL ARTIFACTS.**
- `~/.config/atuin/themes/` — custom theme files. Track if user creates custom themes.

## Output Contract

Return to `cfg` orchestrator:
- Domain: `atuin`
- Action performed: `search_mode`, `sync`, `theme`, `ui`, etc.
- Changed keys (before→after)
- Validation result: `pass` or `fail`
- Commit hash (or "not committed" if validation failed or user didn't confirm)

## References

- `_shared/cfg-common.md` — pipeline contract
- `cfg-chezmoi/SKILL.md` — chezmoi operations
- `~/.config/atuin/config.toml` — real config on disk
- `~/.local/share/chezmoi/dot_config/atuin/config.toml` — chezmoi source copy (in misconfig repo: `chezmoi/dot_config/atuin/config.toml`)
- Docs: https://docs.atuin.sh/cli/configuration/config/
- `AGENTS.md` — hardware constraints (3.7 GiB RAM — daemon uses minimal memory)

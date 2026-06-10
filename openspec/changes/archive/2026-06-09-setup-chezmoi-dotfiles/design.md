# Design: Setup Chezmoi Dotfiles

## Technical Approach

Single chezmoi repo with template-based hostname differentiation. Source tree at `~/.local/share/chezmoi/` using standard `dot_config/` prefix. No remote repo yet — local-first initialization, GitHub remote added during apply. Phase 1 tracks 7 config domains; encryption deferred.

## Architecture Decisions

| Decision | Option A (chosen) | Option B (rejected) | Rationale |
|---|---|---|---|
| **Repo layout** | Standard `dot_config/` prefix | Flat root with `private_` prefixes | Chezmoi-native; `dot_config/niri/config.kdl` → `~/.config/niri/config.kdl` automatically |
| **Multi-machine** | Go templates with `{{ if eq .chezmoi.hostname }}` | Branch-per-machine | Templates scale linearly; branches diverge and create merge debt across machines |
| **Git workflow** | `chezmoi cd` → manual git (add, commit, push) | `chezmoi git` wrapper | Existing `git` knowledge transfers; chezmoi does not provide remote management |
| **Validation** | Manual pre-apply: `chezmoi diff` → `fish -n` → `niri validate` → apply | Pre-commit hooks in chezmoi repo | Chezmoi has no pre-apply hook mechanism; diff review is the chezmoi-certified safety layer |
| **Source directory** | Default: `~/.local/share/chezmoi/` | Custom via `--source ~/misconfig/dotfiles/` | Separate paths avoid self-referencing (misconfig/ is the SDD project, not config source) |
| **Sensitive data** | Deferred to phase 2 as `chezmoi age` | None needed yet | No API keys/tokens exist; `.chezmoi.yaml.tmpl` data file is the architectural plug point |

## Directory Structure

```
~/.local/share/chezmoi/
├── .chezmoi.yaml.tmpl          ← machine data (outputs, DPI, hostname vars)
├── .chezmoiignore              ← dms/*.kdl, fish_variables, misconfig/
├── dot_config/
│   ├── fish/config.fish        ← 12 lines
│   ├── niri/config.kdl.tmpl    ← 279 lines, hostname-conditionals
│   ├── ghostty/config          ← 51 lines, no templates
│   ├── alacritty/dank-theme.toml
│   ├── yazi/{yazi,keymap,theme}.toml + init.lua
│   └── environment.d/90-dms.conf
└── dot_gitconfig.tmpl          ← → ~/.gitconfig, per-machine identity
```

## Template Strategy

Only template files where machines diverge: `niri/config.kdl.tmpl` (outputs, binds, DPI) and `dot_gitconfig.tmpl` (user.name, user.email). Non-divergent files skip `.tmpl` suffix.

```
{{- if eq .chezmoi.hostname "cachyos-x8664" }}
output "eDP-1" { ... }
{{- else }}
output "DP-1" { ... }
{{- end }}
```

`.chezmoi.yaml.tmpl` holds machine data chezmoi merges into `.chezmoi.data`: outputs list, font DPI, git user identity.

## .chezmoiignore Rules

| Pattern | Reason |
|---|---|
| `dot_config/niri/dms/` | DMS auto-generates .kdl files; tracking them creates conflicts |
| `dot_config/fish/fish_variables` | Fish manages universal variables natively |
| `misconfig/` | SDD project repo — self-referencing risk |
| `dot_config/niri/config.kdl` | Exclude the raw file in favor of `config.kdl.tmpl` |

## Installation Bootstrap (New Machine)

```
sudo pacman -S chezmoi                    # 45 MiB, extra repo
sudo snapper create -d pre-chezmoi        # btrfs rollback point
chezmoi init                              # local-first (no remote yet)
chezmoi diff && chezmoi apply --dry-run   # review
chezmoi apply                             # deploy
```

When GitHub remote exists: `chezmoi init --apply juan/<repo-name>`. Git is pre-installed on CachyOS.

## Validation Flow

Pre-apply: `chezmoi diff` → `fish -n` (source directly) → `chezmoi apply --dry-run` → review → `chezmoi apply`. Post-apply: `niri validate` (reads `~/.config/niri/config.kdl`, not source) and `ghostty +validate-config`.

## File Changes

| File | Action | Description |
|---|---|---|
| `~/.local/share/chezmoi/` (directory) | Create | Chezmoi source tree, git-initialized |
| `.chezmoi.yaml.tmpl` | Create | Machine-specific data (outputs, DPI) |
| `.chezmoiignore` | Create | Exclude DMS, fish_variables, misconfig |
| `dot_config/fish/config.fish` | Create | Tracked from existing `~/.config/fish/` |
| `dot_config/niri/config.kdl.tmpl` | Create | Tracked from existing, with hostname templates |
| `dot_config/ghostty/config` | Create | Tracked as-is |
| `dot_config/alacritty/dank-theme.toml` | Create | Tracked, no templates |
| `dot_config/yazi/{yazi,keymap,theme}.toml` + `init.lua` | Create | Multi-file yazi config |
| `dot_config/environment.d/90-dms.conf` | Create | Session environment variables |
| `dot_gitconfig.tmpl` | Create | Per-machine git identity |

## Testing Strategy

| Layer | What to Test | Approach |
|---|---|---|
| Syntax | fish config | `fish -n ~/.config/fish/config.fish` |
| Syntax | niri config (post-template) | `niri validate` against applied file |
| Syntax | ghostty config | `ghostty +validate-config` |
| Dry-run | chezmoi application | `chezmoi apply --dry-run --verbose` |
| Integrity | `.chezmoiignore` coverage | Manual: verify `dms/`, `fish_variables`, `misconfig/` are NOT in `chezmoi managed` output |

No automated test runner available (config repo). Validation is manual, performed before each apply in the workflow.

## Migration / Rollout

No migration required — greenfield project. Rollback: `git revert` inside chezmoi source dir OR `sudo snapper rollback {id}` for btrfs full-restore.

## Open Questions

- [ ] GitHub repo name — `dotfiles` vs `chezmoi-config` vs something else?
- [ ] Second machine hostname — needed to populate `.chezmoi.yaml.tmpl` templates
- [ ] Alacritty: full `alacritty.toml` or just the theme for phase 1?
- [ ] Yazi `flavors/` and `plugins/` subdirs — track or regenerate post-apply?

# Tasks: Setup Chezmoi Dotfiles

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~592 (8 new + 584 imports/templates) |
| 400-line budget risk | High |
| Chained PRs recommended | Yes |
| Suggested split | 5 PRs: Foundation → Core → Desktop → Terminal → Validation |
| Delivery strategy | ask-on-risk |
| Chain strategy | stacked-to-main |

Decision needed before apply: No
Chained PRs recommended: Yes
Chain strategy: stacked-to-main
400-line budget risk: High

### Suggested Work Units

| Unit | Goal | Likely PR | Lines | Notes |
|------|------|-----------|-------|-------|
| 1 | Foundation: chezmoi init, `.chezmoi.yaml.tmpl`, `.chezmoiignore` | PR 1 | ~18 | base=feature/setup-chezmoi-dotfiles |
| 2 | Core: fish `config.fish` + `dot_gitconfig.tmpl` | PR 2 | ~32 | base=PR 1; no app deps anywhere |
| 3 | Desktop: niri `config.kdl.tmpl` (279L templated) + dms env | PR 3 | ~296 | base=PR 2; heaviest single file |
| 4 | Terminal: ghostty (51L) + alacritty (71L) + yazi core (119L) | PR 4 | ~241 | base=PR 3; 6 files, 3 tools |
| 5 | Validation: dry-run, syntax checks, AGENTS.md | PR 5 | ~5 | base=PR 4 |

## Phase 1: Foundation

- [ ] 1.1 Install chezmoi: `sudo pacman -S chezmoi`
- [ ] 1.2 Create btrfs rollback snapshot: `sudo snapper create -d pre-chezmoi`
- [ ] 1.3 Run `chezmoi init` to create `~/.local/share/chezmoi/`
- [ ] 1.4 Create `.chezmoi.yaml.tmpl` with per-machine data (git identity, outputs, fonts)
- [ ] 1.5 Create `.chezmoiignore` excluding `dms/*.kdl`, `fish_variables`, `misconfig/`, raw `config.kdl`

## Phase 2: Core Configs

- [ ] 2.1 Import fish config: `chezmoi add ~/.config/fish/config.fish`
- [ ] 2.2 Create `dot_gitconfig.tmpl` with hostname-templated identity + aliases (`co=checkout`, `st=status`)

## Phase 3: Desktop Environment

- [ ] 3.1 Create `dot_config/niri/config.kdl.tmpl` — copy existing config, add `{{ if eq .chezmoi.hostname "cachyos-x8664" }}` guards for machine-specific blocks (outputs, binds)
- [ ] 3.2 Add placeholder template blocks for desktop machine outputs/binds
- [ ] 3.3 Import DMS env: `chezmoi add ~/.config/environment.d/90-dms.conf`
- [ ] 3.4 Verify `dot_config/niri/dms/` files are NOT in `chezmoi managed` output

## Phase 4: Terminal Tools

- [ ] 4.1 Import ghostty: `chezmoi add ~/.config/ghostty/config`
- [ ] 4.2 Create `dot_config/alacritty/alacritty.toml` full config (font, window, colors pointing to `dank-theme.toml`)
- [ ] 4.3 Import alacritty theme: `chezmoi add ~/.config/alacritty/dank-theme.toml`
- [ ] 4.4 Import yazi core configs: `chezmoi add ~/.config/yazi/yazi.toml ~/.config/yazi/keymap.toml ~/.config/yazi/theme.toml`

## Phase 5: Validation & Polish

- [ ] 5.1 Validate fish syntax: `fish -n ~/.config/fish/config.fish` — must exit 0
- [ ] 5.2 Run `chezmoi apply --dry-run --verbose`, review all diffs
- [ ] 5.3 Run `chezmoi apply` to deploy tracked configs
- [ ] 5.4 Validate niri: `niri validate` against applied `~/.config/niri/config.kdl`
- [ ] 5.5 Validate ghostty: `ghostty +validate-config`
- [ ] 5.6 `git init` chezmoi source dir, create initial commit with all tracked files
- [ ] 5.7 Update `AGENTS.md` with chezmoi workflow note (`diff` → `apply` → validate → commit)

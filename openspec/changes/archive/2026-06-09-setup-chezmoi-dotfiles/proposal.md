# Proposal: Setup Chezmoi Dotfiles

## Intent

Version and sync dotfiles across 2 CachyOS machines (laptop + main PC) using chezmoi. Current configs are unversioned, ad-hoc, and unrecoverable. Establish a single source of truth with machine-aware templating so both machines can coexist in one repo without config collisions.

## Scope

### In Scope (Phase 1)
- Chezmoi initialization (`chezmoi init`) and local repo setup
- 7 config domains tracked: fish, git, niri, ghostty, yazi, dms, alacritty
- Template-based hostname differentiation (`{{ if eq .chezmoi.hostname "..." }}`)
- `.chezmoiignore` for auto-generated files (DMS `/dms/*.kdl`, `fish_variables`)
- New GitHub repo (created during apply, no existing URL)

### Out of Scope
- `chezmoi age` encryption (no secrets exist yet)
- Systemd user units, symlink tracking (phase 2)
- btop, micro, superfile, opencode, zen configs (phase 3+)
- Automated diff/apply on cron or systemd timer
- Multi-OS support (Linux-only for now)

## Capabilities

> `openspec/specs/` is empty — all capabilities are NEW.

### New Capabilities
- `chezmoi-core`: chezmoi init, repo structure, `chezmoi apply` workflow, `.chezmoiignore` rules
- `shell-config`: fish shell — `config.fish`, function paths, CachyOS system integration
- `git-config`: per-machine git user config, aliases, global gitignore
- `niri-config`: Niri compositor `config.kdl` with hostname-templated blocks (outputs, binds)
- `terminal-config`: ghostty config + alacritty theme and config
- `file-manager-config`: yazi lua/toml configs, keymaps, themes
- `launcher-config`: DMS environment variables (`environment.d/90-dms.conf`)

### Modified Capabilities

None (new project).

## Approach

**Single repo, template-based** (Approach A from exploration). Directory structure:

```
~/.local/share/chezmoi/   ← chezmoi source dir
├── .chezmoiignore         ← exclude: dms/*.kdl, fish_variables, misconfig/
├── .chezmoi.yaml.tmpl     ← machine data (hostname, outputs, fonts)
└── dot_config/            ← tracked configs (chezmoi path convention)
    ├── niri/config.kdl.tmpl
    ├── fish/config.fish
    ├── ghostty/config
    ├── yazi/...
    ├── alacritty/...
    └── environment.d/90-dms.conf
```

Templates use hostname guards where machines diverge. Non-divergent configs stay template-free. Chezmoi applies via `chezmoi apply` (dry-run first).

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `~/.local/share/chezmoi/` | New | Source of truth, managed by chezmoi |
| `~/.config/fish/` | Managed | `config.fish` tracked; `fish_variables` excluded |
| `~/.config/niri/config.kdl` | Managed | Tracked with templates; `dms/` excluded |
| `~/.config/ghostty/config` | Managed | Tracked as-is |
| `~/.config/alacritty/` | Managed | Theme + config |
| `~/.config/yazi/` | Managed | Multi-file config |
| `~/.config/environment.d/` | Managed | `90-dms.conf` tracked |
| `~/.gitconfig` | New | Created and tracked |
| GitHub (new repo) | New | Remote for chezmoi source dir |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| DMS regenerates tracked files | Low | `.chezmoiignore` excludes entire `dms/` dir |
| `fish_variables` conflict with chezmoi | Low | Excluded via `.chezmoiignore`; fish manages it natively |
| Package path changes (rolling release) | Low | Chezmoi `stat` checks before apply; easy to update templates |
| Self-referencing: chezmoi tracks `misconfig/` | Low | Explicit `.chezmoiignore` exclusion; different filesystem paths |
| No automated tests | Medium | Manual validation: `niri validate`, `fish -n`, `chezmoi diff` |

## Rollback Plan

1. `chezmoi diff` before every apply — review changes before committing
2. btrfs snapshot before first apply: `sudo snapper create --description pre-chezmoi`
3. Revert individual files: restore from `~/.local/share/chezmoi/` git history
4. Full rollback: `sudo snapper rollback {pre-chezmoi-snapshot-id}`
5. Chezmoi never deletes files unless `chezmoi apply` with `--force` (not used)

## Dependencies

- `chezmoi` package (extra repo, 2.70.5-1) — must be installed
- `git` 2.54.0 (already installed)
- GitHub account for remote repo creation
- `snapper` (pre-installed on CachyOS) for rollback snapshots

## Success Criteria

- [ ] `chezmoi init` completes without errors on both machines
- [ ] All 7 config domains have at least one file tracked
- [ ] `.chezmoiignore` correctly excludes DMS auto-gen files and `fish_variables`
- [ ] `chezmoi apply --dry-run` shows zero unexpected diffs after initial add
- [ ] `fish -n` validates fish config; `niri validate` passes on niri config
- [ ] Git remote configured and `chezmoi cd` repo can push/pull
- [ ] Second machine can `chezmoi init` from the same repo and apply correctly

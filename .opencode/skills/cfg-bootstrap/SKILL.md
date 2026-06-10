---
name: cfg-bootstrap
description: "Trigger: new machine, fresh install, setup dotfiles, onboarding, inicializar dotfiles, bootstrap, máquina nueva. Bootstrap dotfiles on a new CachyOS machine."
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## Activation Contract

Load this skill when the user wants to set up dotfiles on a new CachyOS (Arch-based) machine. This is a SETUP WIZARD — runs ONCE per machine. Not for everyday config changes.

## Hard Rules

- NEVER run `chezmoi apply` without showing `chezmoi diff` first
- NEVER overwrite existing configs without confirmation
- Ask before every `sudo pacman -S` install
- This skill runs ONCE per machine — it's a setup wizard, not a daemon
- All operations are read-only except the ones user explicitly approves

## Decision Gates

| Situation | Action |
|-----------|--------|
| OS is not Arch/CachyOS | Warn: "Tested on CachyOS/Arch only. Continue at your own risk?" |
| Dependencies already installed | Skip pacman install for that package |
| GitHub not authenticated | Guide through `gh auth login` |
| Git identity missing | Prompt for name/email, set via `git config --global` |
| Repo clone fails | Warn: "Repo `jhonmx21/misconfig` not found. Create it first on GitHub." |
| `.chezmoi.yaml.tmpl` has empty identity | Prompt user to fill `name` and `email` |
| Chezmoi diff shows local changes | Show diff, ask before applying |
| Validators unavailable | Warn + skip; show config for manual review |

## Execution Steps

### Step 1: System Check
- Read `/etc/os-release` — verify ID is `cachyos` or `arch`
- Check RAM: `free -m | awk '/^Mem:/{print $2}'` — warn if < 3000 MiB
- Offer to skip pacman installs if dependencies already installed

### Step 2: Dependencies
Check and optionally install:
- `chezmoi` — `sudo pacman -S --needed chezmoi`
- `git` — `sudo pacman -S --needed git`
- `gh` — `sudo pacman -S --needed github-cli`
- Report what's missing, ask before installing

### Step 3: GitHub Identity
- Run `gh auth status` (non-zero → not authenticated)
- If not authenticated: guide user through `gh auth login` (interactive)
- Check `git config --global user.name` and `git config --global user.email`
- If missing: ask user for name/email and set via `git config --global`

### Step 4: Clone misconfig
- Create workspace if needed: `mkdir -p ~/dev`
- Clone: `gh repo clone jhonmx21/misconfig ~/dev/misconfig`
- Fallback: if repo doesn't exist, warn user to create it on GitHub first
- If `~/dev/misconfig` already exists: verify it's the right repo, skip clone

### Step 5: Chezmoi Init
- Run `chezmoi init jhonmx21/misconfig` (uses GitHub repo as source)
- Read `~/.local/share/chezmoi/.chezmoi.yaml.tmpl` and check identity fields (`name`, `email`)
- If empty: prompt user to fill them, then edit the template
- Show `chezmoi diff` — user MUST review before apply
- Run `chezmoi apply` ONLY after user approves diff

### Step 6: Verify
- Run available validators:
  - `fish -n` — validates fish shell syntax (if fish configs exist)
  - `ghostty +validate-config` — validates ghostty config (if `$WAYLAND_DISPLAY` is set)
  - `niri validate` — validates niri config (if niri configs exist)
- Check chezmoi state: `chezmoi diff` should be clean (empty output)
- Report success/failures for each validator

### Step 7: Next Steps
- Tell user skills are available: "Now say 'change ghostty theme' to test"
- Point to `README.md` for full documentation
- Suggest they explore: "Try 'cfg ghostty theme tokyo-night' or 'change font'"

## Output Contract

Return to user:
- OS detected and RAM check result
- Dependencies installed (or skipped)
- GitHub auth status
- Repo cloned (or error)
- Chezmoi init status + diff review result
- Validation results (pass/fail per validator)
- Final chezmoi state (clean/dirty)

## References

- `_shared/cfg-common.md` — pipeline contract (not followed here — bootstrap is a wizard)
- `_shared/cfg-system.md` — config system overview
- `AGENTS.md` — hardware constraints (CachyOS, Broadwell GPU, 3.7 GiB RAM, Niri Wayland)
- `README.md` — full documentation for post-bootstrap usage
- `~/.local/share/chezmoi/.chezmoi.yaml.tmpl` — chezmoi identity template

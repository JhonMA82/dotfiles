---
name: cfg-bootstrap
description: "Trigger: new machine, fresh install, setup dotfiles, onboarding, inicializar dotfiles, bootstrap, máquina nueva. Bootstrap dotfiles on a new CachyOS machine."
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "2.0"
---

## Activation Contract

Load this skill when the user wants to set up dotfiles on a new CachyOS (Arch-based) machine. This is a SETUP WIZARD — runs ONCE per machine. Not for everyday config changes.

## Hard Rules

- NEVER run `chezmoi apply` without showing `chezmoi diff` first
- NEVER overwrite existing configs without confirmation
- Ask before installing ANY package — never auto-install
- This skill runs ONCE per machine — it's a setup wizard, not a daemon
- All operations are read-only except the ones user explicitly approves
- AUR preference: use `paru` if available, `yay` as fallback. Only fall back to AUR if the package is NOT in pacman repos. Check pacman first, then AUR.

## Decision Gates

| Situation | Action |
|-----------|--------|
| OS is not Arch/CachyOS | Warn: "Tested on CachyOS/Arch only. Continue at your own risk?" |
| Package in pacman | `sudo pacman -S --needed <pkg>` |
| Package NOT in pacman, IS in AUR | `paru -S --needed <pkg>` (or `yay`) |
| Tool already installed | Skip install for that tool |
| No config for tool in dotfiles | Skip tool entirely |
| GitHub not authenticated | Guide through `gh auth login` |
| Git identity missing | Prompt for name/email, set via `git config --global` |
| Repo clone fails | Warn: "Repo `jhonmx21/misconfig` not found. Create it first on GitHub." |
| `.chezmoi.yaml.tmpl` has empty identity | Prompt user to fill `name` and `email` |
| Chezmoi diff shows local changes | Show diff, ask before applying |
| Validators unavailable | Warn + skip; show config for manual review |
| No AUR helper found | Warn: "No AUR helper (paru/yay). AUR packages will be skipped." |

## Tool Detection Map

After cloning the repo, scan `chezmoi/dot_config/` to detect which tools have configs. Each entry maps to a tool binary and package:

| Dotfile entry | Tool binary | Package (pacman) | Package (AUR) | Check command |
|--------------|-------------|-------------------|---------------|---------------|
| `ghostty/` | `ghostty` | `ghostty` | — | `which ghostty` |
| `fish/` | `fish` | `fish` | — | `which fish` |
| `niri/` | `niri` | `niri` | — | `which niri` |
| `yazi/` | `yazi` | `yazi` | — | `which yazi` |
| `atuin/` | `atuin` | `atuin` | — | `which atuin` |
| `starship.toml` | `starship` | `starship` | — | `which starship` |

The map is used to:
1. Detect which tools the user's dotfiles cover (only those with configs present)
2. Check which are installed vs missing
3. Install missing ones with correct package source

## Execution Steps

### Step 1: System Check

```bash
# Verify Arch/CachyOS
cat /etc/os-release | grep -E '^ID='

# Check RAM
free -m | awk '/^Mem:/{print $2}'

# Detect AUR helper
which paru 2>/dev/null || which yay 2>/dev/null || echo "NO_AUR_HELPER"
```

- OS: warn if not `cachyos` or `arch`
- RAM: warn if < 3000 MiB
- AUR helper: store `paru` or `yay` for later install steps. If neither found, warn that AUR packages won't be installable.

### Step 2: Base Dependencies

These are ALWAYS required regardless of what tools the user has configs for:

| Tool | Package | Command |
|------|---------|---------|
| chezmoi | `chezmoi` | `sudo pacman -S --needed chezmoi` |
| git | `git` | `sudo pacman -S --needed git` |
| github-cli | `github-cli` | `sudo pacman -S --needed github-cli` |
| AUR helper | `paru` | `sudo pacman -S --needed paru` (if not found in Step 1) |

Check each: `which <tool>` or `pacman -Q <pkg>`. Report what's missing, ASK before installing.

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

### Step 5: Chezmoi Config & Init

The misconfig repo contains the chezmoi source at `~/dev/misconfig/chezmoi/`. We need to tell chezmoi to use this as its source directory.

1. **Create chezmoi config:**
   ```bash
   mkdir -p ~/.config/chezmoi
   ```
   Write `~/.config/chezmoi/chezmoi.toml`:
   ```toml
   sourceDir = "/home/juan/dev/misconfig/chezmoi"
   ```

2. **Initialize chezmoi** with the local source:
   ```bash
   chezmoi init --source ~/dev/misconfig/chezmoi
   ```
   This links chezmoi to the cloned repo without re-cloning from GitHub.

3. Read `~/dev/misconfig/chezmoi/.chezmoi.yaml.tmpl` and check identity fields (`name`, `email`).
4. If empty: prompt user to fill them, then edit the template.

**Do NOT apply yet.** Tool installation must happen first.

### Step 6: Detect Tools & Check Installation

**Scan the cloned repo to discover which tools have configs:**

```bash
ls ~/dev/misconfig/chezmoi/dot_config/
```

Compare the results against the Tool Detection Map. For each matching tool, check if it's installed:

```bash
which <tool> 2>/dev/null && echo "INSTALLED" || echo "MISSING"
```

Build two lists:
- **Installed** — tools already on the system
- **Missing** — tools with configs in the repo but not installed

**Present the summary to the user:**

```
Herramientas detectadas en tus dotfiles:

✅ ghostty     (instalado)
✅ fish        (instalado)
❌ niri        (no instalado)
❌ starship    (no instalado)
✅ yazi        (instalado)

3 instaladas, 2 faltantes.

¿Qué querés hacer?
  [t] Instalar todas las faltantes (niri, starship)
  [e] Elegir cuáles instalar
  [s] Saltar — aplicar solo las que ya están
```

If the user chooses `[e]`, list each missing tool one by one and ask.

### Step 7: Install Missing Tools

For each tool the user chose to install:

1. **Check pacman first:**
   ```bash
   pacman -Si <package> 2>/dev/null
   ```
   If found → `sudo pacman -S --needed <package>`

2. **Fall back to AUR** (only if pacman doesn't have it):
   ```bash
   paru -Si <aur-package> 2>/dev/null
   ```
   If found → `paru -S --needed <aur-package>`

3. **If neither has it:** warn and skip.

**Install command per source:**

| Source | Command |
|--------|---------|
| pacman | `sudo pacman -S --needed <pkg>` |
| AUR (paru) | `paru -S --needed <pkg>` |
| AUR (yay) | `yay -S --needed <pkg>` |

Report each install result. If any fail, note it but continue with remaining tools.

### Step 8: Chezmoi Apply

- Show `chezmoi diff` — user MUST review before applying
- Run `chezmoi apply` ONLY after user approves diff
- If user skipped tool installs, warn that configs for missing tools will be applied but won't take effect until the tool is installed

### Step 9: Verify

Run available validators for installed tools:

| Tool | Validator |
|------|-----------|
| fish | `fish -n` — syntax check |
| ghostty | `ghostty +validate-config` — (only if `$WAYLAND_DISPLAY` set) |
| niri | `niri validate` — config syntax |
| yazi | No validator — inspect config manually |
| atuin | No validator — check TOML syntax manually |
| starship | `starship explain` — parses config (non-zero = error) |

Check chezmoi state: `chezmoi diff` should be clean (empty output).

Report success/failures per validator. For tools without validators, note that manual review was done.

### Step 10: Next Steps

```
¡Listo! Tus dotfiles están aplicados.

Herramientas configuradas: ghostty, fish, niri, yazi, atuin, starship
Herramientas pendientes de instalar: (ninguna / listar las que se saltaron)

Para hacer cambios: "cambiar tema de ghostty a tokyo-night"
Para ver todas las skills: "qué herramientas puedo configurar?"
```

## Output Contract

Return to user:
- OS detected and RAM check result
- AUR helper detected (paru/yay/none)
- Base dependencies installed (or skipped)
- GitHub auth status
- Repo cloned (or error)
- Tool detection summary (installed ✅ / missing ❌)
- Install results per tool (pacman/AUR/skipped)
- Chezmoi init status + diff review result
- Validation results (pass/fail/skipped per validator)
- Final chezmoi state (clean/dirty)

## References

- `_shared/cfg-common.md` — pipeline contract (not followed here — bootstrap is a wizard)
- `_shared/cfg-system.md` — config system overview
- `AGENTS.md` — hardware constraints (CachyOS, Broadwell GPU, 3.7 GiB RAM, Niri Wayland)
- `README.md` — full documentation for post-bootstrap usage
- `~/.config/chezmoi/chezmoi.toml` — chezmoi sourceDir config
- `~/.local/share/chezmoi/.chezmoi.yaml.tmpl` — chezmoi identity template

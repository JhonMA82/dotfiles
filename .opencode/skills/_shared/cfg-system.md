# Config Automation System (cfg)

Natural-language dotfile management via chezmoi + opencode skills. Say "change ghostty theme to tokyo-night" and the system detects the domain, applies the change, validates it, and versions it.

## Quick Path

1. Say what you want: *"change ghostty theme to catppuccin-mocha"*
2. `cfg` detects domain (ghostty) and action (theme)
3. Domain skill applies, validates, and versions the change
4. Your config is tracked, diffed, and committed.

## Available Skills

| Skill | Role | User-facing |
|-------|------|-------------|
| `cfg` | Orchestrator — intent parsing, domain routing | Yes |
| `cfg-ghostty` | Ghostty terminal — theme, font, keybindings | Yes |
| `cfg-chezmoi` | Shared versioning — add, re-add, diff, commit | No |

## The Pipeline

Every domain skill follows the same 5-step contract:

| Step | Action | Blocks on fail? |
|------|--------|:---:|
| **READ** | Load config from chezmoi source + hardware context from `AGENTS.md` | No |
| **PLAN** | Determine field, old→new value; check hardware constraints | No |
| **APPLY** | Edit chezmoi source, preserve structure and comments | No |
| **VALIDATE** | Run domain validator (e.g. `ghostty +validate-config`) | **Yes** |
| **VERSIONAR** | `chezmoi re-add` + conventional commit via `cfg-chezmoi` | No |

Commit format: `type(domain): description` — e.g. `feat(ghostty): change theme to tokyo-night`.

## Adding a New Domain

```
.opencode/skills/cfg-{domain}/SKILL.md
```

Follow the contract from `cfg-common.md`. Define trigger keywords, the validation command (must exit 0), hardware concerns from `AGENTS.md`, and the config path in chezmoi source. Regenerate the registry with `/skill-registry`.

## Multi-Machine Strategy

`.chezmoi.yaml.tmpl` stores per-machine identity (hostname, fonts). Templates use `{{ if eq .chezmoi.hostname "..." }}` blocks for machine-specific configs. Domain skills read template data before applying. Current setup: single-machine MVP (`cachyos-x8664`).

## Hardware-Aware Defaults

Every skill reads `AGENTS.md` before suggesting settings:

| Constraint | Impact |
|------------|--------|
| Intel Broadwell-U GPU | No `background-blur`; use `opacity` |
| 3.7 GiB RAM | Lightweight defaults; prefer skills |
| Niri Wayland | Set `linux_display_server wayland` |

## File Layout

```
~/.local/share/chezmoi/          ← chezmoi source (versioned)
├── .chezmoi.yaml.tmpl           ← machine identity
├── .chezmoiignore
└── dot_config/ghostty/config

.opencode/skills/                ← project skills (versioned)
├── _shared/
│   ├── cfg-common.md            ← pipeline contract
│   └── cfg-system.md            ← this document
├── cfg/SKILL.md                 ← orchestrator
├── cfg-chezmoi/SKILL.md         ← versioning
└── cfg-ghostty/SKILL.md         ← ghostty domain
```

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| "No cfg-{domain} skill found" | Skill doesn't exist. Create it or use a known domain. |
| Validation fails | Syntax error in config. Fix and re-apply. |
| chezmoi overwrites changes | You edited source, not destination. Edit `~/.config/...` then `chezmoi re-add`. |
| Commit not appearing | `chezmoi cd && git log --oneline -5` |

## Checklist

- [ ] `cfg-*` skills registered in `.atl/skill-registry.md`
- [ ] `.chezmoi.yaml.tmpl` has machine data
- [ ] Validation passes before every commit
- [ ] Commits use `type(domain): description` format
- [ ] `_shared/cfg-common.md` is the single source of truth for the pipeline contract

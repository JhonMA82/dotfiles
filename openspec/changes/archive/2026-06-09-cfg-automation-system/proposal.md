# Proposal: Config Automation System

## Intent

Build a config management automation system where the user says "change ghostty theme to tokyo-night" and an orchestrator skill routes to a domain skill that edits chezmoi-managed templates, validates syntax, and commits. Open by design — new domains added by creating a single `SKILL.md`.

## Scope

### In Scope (Phase 1 — MVP)
- `cfg` orchestrator skill — intent routing, domain discovery via skill registry
- `cfg-chezmoi` shared skill — chezmoi ops (add, re-add, diff, apply, commit)
- `cfg-ghostty` domain skill — ghostty config management (theme, font, keybindings)
- `.chezmoi.yaml.tmpl` — machine data template with identity placeholders (git name/email defined at `chezmoi init`)
- `.chezmoiignore` — DMS exclusion, `fish_variables`, caches
- Shared reference: `_shared/cfg-common.md` — READ→PLAN→APPLY→VALIDATE→VERSIONAR contract

### Out of Scope (Phase 2)
- `cfg-niri`, `cfg-fish`, `cfg-git`, `cfg-yazi`, `cfg-dms`, `cfg-alacritty`
- GitHub remote pushes
- Multi-machine template conditionals beyond current hostname (`cachyos-x8664`)

## Capabilities

### New Capabilities
- `cfg-orchestrator`: intent parsing (keyword + pattern match), domain routing via skill registry, chained domain execution
- `cfg-chezmoi`: shared chezmoi operations — add, re-add, diff, apply, commit with conventional commits (`feat(domain): ...`)
- `cfg-ghostty`: ghostty domain — theme switching, font changes, keybinding edits, `+validate-config` pre-commit

### Modified Capabilities
- `chezmoi-core`: extend existing manual workflow (init/apply/diff) with automation contract — domain skills as clients, standardized commit format, shared validation pipeline via `cfg-chezmoi`

## Approach

**Orchestrator `cfg` + domain skills `cfg-{domain}`** (Approach B from exploration):

```
User: "change ghostty font to JetBrains Mono"
  → cfg orchestrator: parse domain=ghostty, action=modify, key=font
  → load cfg-ghostty SKILL.md + cfg-chezmoi for shared ops
  → cfg-ghostty: read source → edit → validate (ghostty +validate-config)
  → cfg-chezmoi: chezmoi re-add → git commit (feat(ghostty): ...)
  → report diff to user
```

Skills (not sub-agents) — lighter on RAM (3.7 GiB constraint), share context. Each domain skill follows standardized contract: READ → PLAN → APPLY → VALIDATE → VERSIONAR. Validation mandatory before commit — never commit broken config. Skills read `AGENTS.md` for hardware context. `context7` used for up-to-date tool docs.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `~/.config/opencode/skills/cfg/` | New | Orchestrator skill |
| `~/.config/opencode/skills/cfg-chezmoi/` | New | Shared chezmoi operations |
| `~/.config/opencode/skills/cfg-ghostty/` | New | Ghostty domain skill |
| `~/.config/opencode/skills/_shared/cfg-common.md` | New | Standardized contract reference |
| `~/.local/share/chezmoi/` | Modified | Source tree populated with configs |
| `.chezmoi.yaml.tmpl` | New | Machine data with identity placeholders |
| `.chezmoiignore` | New | Exclude DMS, fish_variables, caches |
| `.atl/skill-registry.md` | Modified | Regenerated after skill creation |
| `openspec/specs/chezmoi-core/spec.md` | Modified | Delta spec for automation contract |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| `ghostty +validate-config` unavailable without display server | Medium | Fallback: diff inspection + syntax review |
| Skill registry drift after creation | Low | Regenerate `.atl/skill-registry.md` as final step |
| `.chezmoi.yaml.tmpl` missing blocks first domain skill that needs it | Medium | `cfg-chezmoi` checks for template file existence before delegating |
| Sub-agent RAM for sequential multi-domain requests | Low | Finish one domain fully before spawning next; domain skills are lightweight (~100 lines each) |

## Rollback Plan

1. Delete `cfg`, `cfg-chezmoi`, `cfg-ghostty` skill directories from `~/.config/opencode/skills/`
2. Remove `_shared/cfg-common.md`
3. Regenerate `.atl/skill-registry.md`
4. Revert chezmoi source tree changes via `chezmoi cd && git reset --hard HEAD~1`

## Dependencies

- Chezmoi 2.70.5 (installed, source tree at `~/.local/share/chezmoi/`)
- Ghostty terminal (installed, config at `~/.config/ghostty/config`)
- Skill registry at `.atl/skill-registry.md` (must regenerate after creating skills)

## Success Criteria

- [ ] `cfg` orchestrator routes "change ghostty theme to X" to `cfg-ghostty`
- [ ] `cfg-ghostty` edits chezmoi source and commits with conventional format
- [ ] `cfg-chezmoi` handles first-add (empty source tree) and re-add cases
- [ ] Validation runs pre-commit; broken config blocks commit
- [ ] `.chezmoiignore` excludes DMS auto-generated files
- [ ] `.chezmoi.yaml.tmpl` exists with machine identity placeholders

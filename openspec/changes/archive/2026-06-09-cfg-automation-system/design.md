# Design: Config Automation System

## Technical Approach

Orchestrator `cfg` + domain skills `cfg-{domain}`. Skills run in caller's context (3.7 GiB RAM constraint). Standardized READ→PLAN→APPLY→VALIDATE→VERSIONAR contract in `_shared/cfg-common.md`. Validation blocks commit.

## Architecture Decisions

| Decision | Choice | Alternatives | Rationale |
|----------|--------|-------------|-----------|
| **File layout** | `~/.config/opencode/skills/cfg-{domain}/SKILL.md`, user scope | Project skills, monolith | `cfg-*` prefix enables discovery; user scope works across repos |
| **Frontmatter** | `name: cfg-ghostty`, single-line `description` ≤250 chars, trigger words first | OpenCode built-in | Follows skill-creator: `name`, `description`, `license`, `metadata.*` |
| **Contract pipeline** | READ→PLAN→APPLY→VALIDATE→VERSIONAR in `_shared/cfg-common.md` | Ad-hoc per-skill | Shared reference prevents drift; cfg-chezmoi handles VERSIONAR universally |
| **Intent parsing** | Keyword + pattern match: domain=ghostty, action=modify, key, value | Full NLU | Sufficient for structured commands; ambiguous "cambiá el tema" → ask user |
| **Domain discovery** | Read `<available_skills>`, match `cfg-*` prefix | Registry-only, hardcoded | `<available_skills>` always present, authoritative |
| **Pre-commit validation** | Domain tool runs; failure blocks commit | Post-commit, skip | Never commit broken config; fish `-n`, niri `validate`, ghostty `+validate-config` |
| **Validation fallback** | Tool missing → warn + diff; no `$WAYLAND_DISPLAY` → skip display tools | Hard-fail | TTY can't validate niri/ghostty; diff is the safety net |
| **Commit authorship** | `cfg-chezmoi` runs `chezmoi cd -- git commit -m "feat({domain}): {desc}"` | Domain commits directly | Single path = consistent format |
| **First-add vs re-add** | cfg-chezmoi checks source tree → `chezmoi add` (new) or `chezmoi re-add` (tracked) | Always `add --force` | `re-add` preserves attributes; `add` avoids overwrite |
| **Multi-machine (MVP)** | No `{{ if eq .chezmoi.hostname }}` guards; single machine `cachyos-x8664` | Template everything now | MVP scope: one machine; templating adds no value until Phase 2 |
| **Hardware-aware defaults** | Read AGENTS.md before suggesting values | Hardcoded, context7 | Authoritative: Broadwell GPU, screen res, 3.7 GiB |
| **Skill registration** | Manual: run `skill-registry` after creating cfg-*; runtime via `<available_skills>` | Auto-hook | Regeneration cheap; runtime discovery independent of registry freshness |

## Data Flow

```
User: "change ghostty font to JetBrains Mono"
  │
  ▼
cfg (loaded via skill tool)
  │  Parse: domain=ghostty, action=modify, key=font, value="JetBrains Mono"
  │  Route: cfg-ghostty from <available_skills>
  ▼
cfg-ghostty (skill tool, same context)
  │  READ:   chezmoi source + AGENTS.md + .chezmoi.yaml.tmpl
  │  PLAN:   edit plan (field, old, new)
  │  APPLY:  write to source tree
  │  VALIDATE: ghostty +validate-config (or warn+diff in TTY)
  │  VERSIONAR → cfg-chezmoi
  ▼
cfg-chezmoi (skill tool)
  │  chezmoi re-add → git commit "feat(ghostty): change font to JetBrains Mono"
  ▼
cfg: report diff + commit hash to user
```

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `~/.config/opencode/skills/cfg/SKILL.md` | Create | Orchestrator: intent parsing, routing |
| `~/.config/opencode/skills/cfg-chezmoi/SKILL.md` | Create | Shared chezmoi ops: add/re-add/diff/apply/commit |
| `~/.config/opencode/skills/cfg-ghostty/SKILL.md` | Create | Ghostty domain: theme, font, keybindings |
| `~/.config/opencode/skills/_shared/cfg-common.md` | Create | READ→PLAN→APPLY→VALIDATE→VERSIONAR contract |
| `~/.local/share/chezmoi/dot_config/ghostty/config` | Create | Ghostty config in chezmoi source |
| `misconfig/.chezmoi.yaml.tmpl` | Create | Machine identity (hostname, git name/email) |
| `misconfig/.chezmoiignore` | Create | Exclude DMS, fish_variables, caches |
| `misconfig/.atl/skill-registry.md` | Modify | Regenerate after skill creation |
| `openspec/specs/chezmoi-core/spec.md` | Modify | Delta spec: automation contract |

## Contract Interface (`_shared/cfg-common.md`)

| Step | Inputs | Outputs |
|------|--------|---------|
| **READ** | Domain name, config path | Current state + hardware context |
| **PLAN** | Current state, user intent | Edit plan (field, old value, new value) |
| **APPLY** | Edit plan, source path | Modified file path |
| **VALIDATE** | Source path, domain | `pass`/`fail` + error output |
| **VERSIONAR** | Domain, description, changed files | Commit hash |

## Validation Pipeline

| Domain | Command | Fallback |
|--------|---------|----------|
| ghostty | `ghostty +validate-config` | Diff inspection (TTY-safe) |
| fish | `fish -n {file}` | None needed |
| niri | `niri validate` | Skip + warn (needs WAYLAND_DISPLAY) |
| alacritty | None | Diff inspection only |
| yazi | None | Diff inspection only |
| git | `git config --list --file {file}` | Diff inspection |

## Testing Strategy

No automated runner (`strict_tdd: false`). Each VALIDATE step serves as integration test. Manual E2E: user issues command → verifies source update + commit. Diff inspection as universal fallback.

## Open Questions

- [ ] Cache `<available_skills>` or re-read each invocation? (Re-read safer, ~50ms cost)
- [ ] `.chezmoi.yaml.tmpl` hostname: chezmoi `data.hostname` or `$HOSTNAME`? (Auto preferred)
- [ ] Validation failure: stash uncommitted change or discard? (Stash preserves for inspection)

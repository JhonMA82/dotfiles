# Tasks: Config Automation System

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~313 (templates: ~18, skills: ~260, contract: ~30, AGENTS: ~5) |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single PR |
| Delivery strategy | ask-always |

Decision needed before apply: Yes
Chained PRs recommended: No
Chain strategy: pending
400-line budget risk: Low

### Suggested Work Units

| Unit | Goal | Likely PR | Notes |
|------|------|-----------|-------|
| 1 | Full MVP: 3 skills + 2 templates + contract + registry | PR 1 | All under 400 lines; verify skill sizes before apply |

## Phase 1: Foundation — Templates + Shared Contract + cfg-chezmoi

- [x] 1.1 Create `~/.local/share/chezmoi/.chezmoi.yaml.tmpl` with `{{ .name }}`, `{{ .email }}`, hostname (`cachyos-x8664`)
- [x] 1.2 Create `~/.local/share/chezmoi/.chezmoiignore` excluding `dms/*.kdl`, `fish_variables`, cache dirs
- [x] 1.3 Create `~/.config/opencode/skills/_shared/cfg-common.md` with READ→PLAN→APPLY→VALIDATE→VERSIONAR contract
- [x] 1.4 Create `~/.config/opencode/skills/cfg-chezmoi/SKILL.md` with add/re-add/diff/commit workflow + conventional commit format
- [x] 1.5 Test first-add: `chezmoi add ~/.config/ghostty/config` → verify `dot_config/ghostty/config` created in source tree
- [x] 1.6 Commit initial state via cfg-chezmoi contract: `feat(chezmoi): add ghostty config`

## Phase 2: Domain — cfg-ghostty Skill

- [x] 2.1 Create `~/.config/opencode/skills/cfg-ghostty/SKILL.md` following READ→PLAN→APPLY→VALIDATE→VERSIONAR contract
- [x] 2.2 Implement theme change: parse `theme = {value}`, update source, validate, re-add
- [x] 2.3 Implement font change: read AGENTS.md for hardware context (Broadwell GPU, 3.7 GiB), prefer opacity over blur
- [x] 2.4 Implement plugin installation: manage `plugin=` lines, handle TTY fallback (warn + diff)
- [x] 2.5 Implement keybinding modification: append/edit `keybind =` entries
- [x] 2.6 E2E test: "change ghostty theme to tokyo-night" → validate `ghostty +validate-config` → commit `feat(ghostty): change theme to tokyo-night`

## Phase 3: Orchestrator — cfg Skill

- [x] 3.1 Create `~/.config/opencode/skills/cfg/SKILL.md` with intent parsing (keyword + pattern match)
- [x] 3.2 Implement domain detection: read `<available_skills>`, match `cfg-*` prefix
- [x] 3.3 Implement delegation: `skill()` tool loads matched `cfg-{domain}` SKILL.md
- [x] 3.4 Implement error handling: domain not found → suggest closest match; ambiguous → ask user
- [x] 3.5 E2E test: "cambiá el tema de ghostty a catppuccin" → cfg routes → cfg-ghostty applies → validates → commits

## Phase 4: Registry & Polish

- [x] 4.1 Regenerate skill registry via `skill-registry` skill
- [x] 4.2 Verify `<available_skills>` includes `cfg`, `cfg-chezmoi`, `cfg-ghostty`
- [x] 4.3 Update `AGENTS.md` with cfg system workflow reference
- [x] 4.4 Full E2E smoke test: user intent → orchestrator → domain → chezmoi → validated commit → diff report

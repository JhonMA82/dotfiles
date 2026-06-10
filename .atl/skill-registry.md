# Skill Registry — misconfig

> Auto-generated index for sub-agent delegation.
> `SKILL.md` remains the source of truth — agents MUST read the referenced file before acting.
> Generated: 2026-06-09 | Mode: openspec | Scope: user + project

## Registry Contract

- The registry is an index of trigger-to-path mappings, not a skill summary.
- Every row identifies one skill with its trigger, scope, and exact `SKILL.md` path.
- Delegators pass the path to sub-agents; sub-agents read the real `SKILL.md`.
- Do NOT generate compact rules from this index.

## Convention Files

| File | Path | Scope |
|------|------|-------|
| AGENTS.md | `/home/juan/misconfig/AGENTS.md` | project |

## Indexed Skills (15)

| # | Skill | Trigger | Scope | Path |
|---|-------|---------|-------|------|
| 1 | branch-pr | creating, opening, or preparing PRs for review | user | `~/.config/opencode/skills/branch-pr/SKILL.md` |
| 2 | cachyos-troubleshoot | system problems (wifi, audio, boot, kernel panic, Niri, snapshots, pacman, AUR, etc.) | user | `~/.config/opencode/skills/cachyos-troubleshoot/SKILL.md` |
| 3 | cfg | cambiar, configurar, tema, fuente, plugin, instalar, dotfiles, cfg, configure, setup | project | `.opencode/skills/cfg/SKILL.md` |
| 4 | cfg-chezmoi | chezmoi add, re-add, diff, apply, commit, dotfiles versioning | project | `.opencode/skills/cfg-chezmoi/SKILL.md` |
| 5 | cfg-ghostty | ghostty, terminal, theme, font, plugin, keybinding, opacity, padding, cursor | project | `.opencode/skills/cfg-ghostty/SKILL.md` |
| 6 | cfg-yazi | yazi, file manager, opener, glow, keymap, theme, preview, markdown, md | project | `.opencode/skills/cfg-yazi/SKILL.md` |
| 7 | chained-pr | PRs over 400 lines, stacked PRs, review slices | user | `~/.config/opencode/skills/chained-pr/SKILL.md` |
| 8 | cognitive-doc-design | writing guides, READMEs, RFCs, onboarding, architecture, or review-facing docs | user | `~/.config/opencode/skills/cognitive-doc-design/SKILL.md` |
| 9 | comment-writer | PR feedback, issue replies, reviews, Slack messages, or GitHub comments | user | `~/.config/opencode/skills/comment-writer/SKILL.md` |
| 10 | go-testing | Go tests, go test coverage, Bubbletea teatest, golden files | user | `~/.config/opencode/skills/go-testing/SKILL.md` |
| 11 | issue-creation | creating GitHub issues, bug reports, or feature requests | user | `~/.config/opencode/skills/issue-creation/SKILL.md` |
| 12 | judgment-day | judgment day, dual review, adversarial review, juzgar | user | `~/.config/opencode/skills/judgment-day/SKILL.md` |
| 13 | skill-creator | new skills, agent instructions, documenting AI usage patterns | user | `~/.config/opencode/skills/skill-creator/SKILL.md` |
| 14 | skill-improver | improve skills, audit skills, refactor skills, skill quality | user | `~/.config/opencode/skills/skill-improver/SKILL.md` |
| 15 | work-unit-commits | implementation, commit splitting, chained PRs, or keeping tests and docs with code | user | `~/.config/opencode/skills/work-unit-commits/SKILL.md` |

## Skipped / Deduplicated

| Skill | Reason |
|-------|--------|
| customize-opencode | Built-in (no file path), excluded |
| sdd-apply | SDD internal skill — excluded |
| sdd-archive | SDD internal skill — excluded |
| sdd-design | SDD internal skill — excluded |
| sdd-explore | SDD internal skill — excluded |
| sdd-init | SDD internal skill — excluded |
| sdd-onboard | SDD internal skill — excluded |
| sdd-propose | SDD internal skill — excluded |
| sdd-spec | SDD internal skill — excluded |
| sdd-tasks | SDD internal skill — excluded |
| sdd-verify | SDD internal skill — excluded |
| _shared | Shared references — not a skill |
| skill-registry | Registry itself — excluded |

## Scan Sources

- User skills: `~/.config/opencode/skills/` (23 found, 11 indexed)
- Project skills: `.opencode/skills/` (4 found, 4 indexed)
- Convention files: `AGENTS.md` (1 found)

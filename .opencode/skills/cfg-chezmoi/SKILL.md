---
name: cfg-chezmoi
description: "Trigger: chezmoi add, chezmoi re-add, chezmoi diff, chezmoi apply, chezmoi commit, dotfiles versioning. Shared chezmoi operations for all cfg-* domain skills — add, re-add, diff, apply, commit."
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## Activation Contract

Load this skill when any `cfg-{domain}` skill needs to version a config change. This is the single entry point for all chezmoi operations — domain skills MUST NOT run chezmoi commands directly.

## Hard Rules

- NEVER commit without prior validation. Commit ONLY after the calling domain skill confirms VALIDATE passed.
- Use `chezmoi re-add` for tracked files, `chezmoi add` for first-time imports.
- All commits MUST follow Conventional Commits: `type(domain): description`.
- Run all chezmoi commands from within the chezmoi source tree (`~/.local/share/chezmoi/`).
- Always show `chezmoi diff` to the user before applying.

## Decision Gates

| Situation | Action |
|-----------|--------|
| File NOT in source tree | `chezmoi add {path}` |
| File IS tracked | `chezmoi re-add` |
| User wants preview only | `chezmoi diff` — no write, no commit |
| Validation passed | Commit with conventional format |
| Validation failed | Block — do NOT commit |

## Execution Steps

### First-Add Workflow

```
Domain skill calls first-add: "track ~/.config/ghostty/config"
  → chezmoi add ~/.config/ghostty/config
  → Verify file created at dot_config/ghostty/config in source
  → Return source path
```

### Re-Add Workflow

```
Domain skill calls re-add: "ghostty config updated"
  → chezmoi re-add
  → Show diff: chezmoi diff
  → Commit: git add -A && git commit -m "feat(ghostty): {description}"
  → Return commit hash
```

### Diff Workflow

```
Domain skill calls diff: "preview ghostty changes"
  → chezmoi diff
  → Return diff output — NO writes, NO commit
```

### Commit Wireframe

```bash
chezmoi cd                   # or: cd ~/.local/share/chezmoi
chezmoi re-add                # stage updated configs
git diff --cached --stat      # preview
git commit -m "type(domain): description"
```

## Output Contract

Return to calling domain skill:
- Source file path(s) affected
- Diff summary (changed lines)
- Commit hash (if committed)
- Operation: `first-add`, `re-add`, or `diff-only`

## References

- `~/.config/opencode/skills/_shared/cfg-common.md` — pipeline contract all domain skills follow
- `~/.local/share/chezmoi/` — chezmoi source tree

# cfg-common — Shared Config Automation Contract

> Reference for cfg orchestrator and all `cfg-{domain}` skills. Not invokable.

## Pipeline: READ → PLAN → APPLY → VALIDATE → VERSIONAR

Every domain skill MUST follow this 5-step pipeline in order. No step may be skipped.

### Step 1 — READ

| Contract | Detail |
|----------|--------|
| **Input** | Domain name, config path (chezmoi source) |
| **Action** | Read current config state from chezmoi source tree + hardware context from `AGENTS.md` |
| **Output** | Current config contents + hardware constraints (GPU, RAM, display) |

### Step 2 — PLAN

| Contract | Detail |
|----------|--------|
| **Input** | Current state (from READ), user intent (action, key, value) |
| **Action** | Determine change type (add, modify, remove), compute old→new values, check hardware constraints |
| **Output** | Edit plan: field to change, old value, new value, impacted hardware concerns |

### Step 3 — APPLY

| Contract | Detail |
|----------|--------|
| **Input** | Edit plan (from PLAN), source file path |
| **Action** | Modify the chezmoi source file. Preserve existing structure, comments, and whitespace. |
| **Output** | Modified file path + diff |

### Step 4 — VALIDATE

| Contract | Detail |
|----------|--------|
| **Input** | Modified file path, domain name |
| **Action** | Run domain-specific validator (e.g., `ghostty +validate-config`, `fish -n`). If validator unavailable (TTY, no display server), warn + use diff inspection as fallback. |
| **Output** | `pass` or `fail` with error output. VALIDATE MUST PASS before continuing to VERSIONAR. |

### Step 5 — VERSIONAR

| Contract | Detail |
|----------|--------|
| **Input** | Domain name, change description, validated file paths |
| **Action** | Delegate to `cfg-chezmoi` for: `chezmoi re-add` → `git commit` |
| **Output** | Commit hash + diff summary |

## Error Handling Rules

1. **Validator unavailable**: warn user, show diff, do NOT block — allow manual review override.
2. **Validator fails**: BLOCK the pipeline — return error to user with failing output. Do NOT commit.
3. **Source file not found**: treat as first-add → delegate to `cfg-chezmoi` for `chezmoi add` path.
4. **Hardware concern flagged**: warn user, require explicit confirmation before proceeding (e.g., "Broadwell GPU does not support blur; use opacity instead. Continue?").

## Commit Message Format

All commits MUST follow Conventional Commits:

```
type(domain): description
```

| Type | When to use |
|------|-------------|
| `feat` | New config entry, setting, or behavior |
| `fix` | Correction to broken/incorrect config |
| `style` | Whitespace, formatting, comments only |
| `chore` | Reorganization, ignore rules, template maintenance |

Examples: `feat(ghostty): change theme to catppuccin`, `fix(fish): correct PATH ordering`

## Hardware Awareness

Every domain skill MUST read `AGENTS.md` (from project root or `~/.config/opencode/AGENTS.md`) before suggesting or applying changes. Key constraints:

- **GPU**: Intel Broadwell-U — avoid `background-blur`, prefer `opacity`
- **RAM**: 3.7 GiB — prefer skills over sub-agents
- **Display**: Niri Wayland — do not assume X11 or i3/Sway config syntax
- **Hostname**: `cachyos-x8664` — single-machine MVP

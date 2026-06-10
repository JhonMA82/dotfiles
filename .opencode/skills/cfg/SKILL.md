---
name: cfg
description: "Trigger: cambiar, configurar, tema, fuente, plugin, instalar, dotfiles, cfg, configure, setup. Orchestrator that routes config automation requests to domain-specific cfg-* skills."
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## Activation Contract

Load this skill when the user asks to change, configure, or manage any dotfile — theme changes, font updates, plugin installs, keybinding edits, or any "cfg/configure/setup" request. This is the ENTRY POINT for all config automation.

## Hard Rules

- **cfg is the MANDATORY gatekeeper for ALL dotfile, config, or tool-setup changes.** Whether the tool is known (ghostty, fish) or unknown (atuin, starship, bat), you MUST route through cfg. Never run chezmoi directly, never add files directly, never edit configs without cfg approval. cfg alone decides whether to delegate to an existing `cfg-{domain}` skill or offer to create one.
- Parse intent FIRST, confirm with user SECOND, delegate THIRD. Never skip confirmation when ambiguous.
- Read `<available_skills>` at runtime to discover available `cfg-*` domain skills.
- Use keyword matching, not full NLU. The intent parser is a pattern matcher — simple, fast, and predictable.
- If no `cfg-*` domain skill matches, offer to create one. Never silently drop the request.

## Decision Gates

| Situation | Action |
|-----------|--------|
| Domain detected, action clear | Confirm: "I detect domain={domain}, action={action}. Routing to cfg-{domain}. OK?" |
| Domain detected, action ambiguous | Ask user to clarify: "What do you want to do with {domain}?" |
| Domain not in keyword table (unknown tool) | Extract the tool name from the user's message. Ask: "No conozco {tool}. ¿Qué es, qué hace, y tenés una URL de documentación?" Only after understanding the tool, offer to create `cfg-{tool}`. **If a new cfg-* skill is created, you MUST also: (1) add domain to keyword table in this file, (2) add skill to README.md Available Skills table, (3) update `.atl/skill-registry.md`.** Never proceed to chezmoi directly. |
| Domain not found (cfg-* skill missing) | List available cfg-* skills. Suggest creating `cfg-{domain}`. |
| Multiple domains match | Ask user to choose: "Did you mean ghostty, fish, or niri?" |
| No cfg-* skills exist | "No config automation skills installed yet. Want me to create one?" |

## Execution Steps

### Step 1: Parse Intent

Extract from user message:

| Keyword Pattern | Maps To |
|----------------|---------|
| ghostty, terminal, alacritty | domain = ghostty |
| fish, shell, alias, path, function, plugin, fisher, abbr, fzf, zoxide, eza, exa, ls | domain = fish |
| niri, compositor, wayland, tiling, outputs, binds, window-rules, animaciones, gaps, layout, monitores, pantallas | domain = niri |
| starship, prompt, starship theme, starship preset, starship module, prompt theme, prompt config | domain = starship |
| yazi, file, explorer, fm, opener, glow, markdown, md, preview | domain = yazi |
| atuin, shell history, sync, search, daemon, stats, ctrl-r | domain = atuin |
| bootstrap, new machine, fresh install, setup dotfiles, onboarding, inicializar, máquina nueva | domain = bootstrap (one-time setup wizard) |
| git, commit, branch, repo | domain = git (deferred) |
| theme, tema | action = theme |
| font, fuente, typography | action = font |
| plugin, extension, addon | action = plugin |
| keybinding, atajo, shortcut, bind | action = keybinding |
| add, agregar, instalar, install | action = add |
| opacity, transparencia | action = opacity |
| padding, margin, spacing | action = padding |

Keyword matching is case-insensitive and supports Spanish and English.

### Step 2: Domain Discovery

Read `<available_skills>` from system prompt context. Match all skills whose `name` starts with `cfg-`. The suffix after `cfg-` is the domain identifier.

```
<available_skills> → [cfg, cfg-chezmoi, cfg-ghostty, ...]
Available domains: [chezmoi, ghostty]  (cfg-chezmoi is shared infra, not a user-facing domain)
User-facing domains: [ghostty]
```

### Step 3: Delegate

Once domain is confirmed and user approves:
1. Load the domain skill: `skill("cfg-{domain}")`
2. Hand off the parsed intent: domain, action, key, value
3. The domain skill executes READ→PLAN→APPLY→VALIDATE→VERSIONAR
4. Report the result back to the user

Delegation flow:
```
cfg (this skill)
  │  Parse intent
  │  Confirm with user
  │  skill("cfg-ghostty")
  ▼
cfg-ghostty
  │  READ → PLAN → APPLY → VALIDATE
  │  → cfg-chezmoi for VERSIONAR
  ▼
cfg-chezmoi
  │  chezmoi re-add → git commit
  ▼
cfg reports: "Theme changed to tokyo-night. Commit: 222ca2b"
```

### Step 4: Error Handling

| Error | Response |
|-------|----------|
| No domain detected (unrecognized tool) | Extract tool name from user message. "No conozco {tool}. ¿Qué es, qué hace, y tenés una URL de documentación?" Then offer to create cfg-{tool} if appropriate. |
| No domain detected (vague request) | "I didn't detect a known tool in your request. What tool or config file are you working with?" |
| No cfg-* domain skill | "No cfg-{domain} skill exists yet. Want me to create one? We'd need a SKILL.md with the READ→PLAN→APPLY→VALIDATE→CONFIRM→VERSIONAR pipeline." |
| Ambiguous domain (matches 2+) | "Your request could match {domains}. Which one did you mean?" |
| Domain skill exists but is deferred/not implemented | "cfg-{domain} exists but is not yet implemented. It's deferred to Phase 2." |

## Output Contract

Return to user:
- Parsed intent (domain, action)
- Confirmation prompt or delegation result
- If delegated: action summary, changed lines, commit hash

## References

- `_shared/cfg-common.md` — pipeline contract for all domain skills
- `cfg-chezmoi/SKILL.md` — shared chezmoi versioning operations
- `cfg-ghostty/SKILL.md` — ghostty domain skill
- `cfg-fish/SKILL.md` — fish shell domain skill
- `cfg-niri/SKILL.md` — niri compositor domain skill
- `cfg-yazi/SKILL.md` — yazi domain skill
- `cfg-bootstrap/SKILL.md` — new-machine onboarding wizard
- `<available_skills>` — runtime skill discovery
- `AGENTS.md` — hardware constraints

# Delta for chezmoi-core

## ADDED Requirements

### Requirement: Programmatic Add/Re-add
MUST support `chezmoi add` and `chezmoi re-add` via skills.

#### Scenario: Add and re-add
- GIVEN skill requests config tracking or re-track
- WHEN `chezmoi add` or `chezmoi re-add` runs
- THEN file added/updated with `dot_` prefix before commit

### Requirement: Pre-commit Validation
MUST validate config via domain-specific validators before commit.

#### Scenario: Validation gate
- GIVEN config staged
- WHEN validator runs (e.g., `ghostty +validate-config`)
- THEN commit proceeds on success, blocked with error on failure

## MODIFIED Requirements

### Requirement: Init Source Directory
MUST init chezmoi source at `~/.local/share/chezmoi` with `dot_config/` AND `.chezmoi.yaml.tmpl` containing identity placeholders.
(Previously: Init without `.chezmoi.yaml.tmpl`)

#### Scenario: Init with template
- GIVEN no source dir
- WHEN `chezmoi init` runs
- THEN `dot_config/` ready AND `.chezmoi.yaml.tmpl` created with `{{ .name }}`, `{{ .email }}`

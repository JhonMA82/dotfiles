# cfg-chezmoi Specification

Shared chezmoi operations: add, diff, apply, commit.

## Requirements

### Requirement: Add and Re-add
MUST support `chezmoi add` (first-time, empty tree) and `chezmoi re-add` (updated files).

#### Scenario: First-time add
- GIVEN empty source tree, skill requests tracking
- WHEN `chezmoi add` runs
- THEN file added with `dot_` prefix

#### Scenario: Re-add after edit
- GIVEN tracked file modified by skill
- WHEN `chezmoi re-add` runs
- THEN source copy updated before commit

### Requirement: Diff and Dry-Run
MUST display `chezmoi diff` and support `--dry-run` before apply.

#### Scenario: Preview before apply
- GIVEN staged changes
- WHEN diff or dry-run is requested
- THEN deltas displayed, nothing written

### Requirement: Conventional Commits
MUST commit with format `type(domain): description`.

#### Scenario: Commit after validation
- GIVEN validated and staged changes
- WHEN commit runs
- THEN message follows `feat(domain):` or `fix(domain):` convention

### Requirement: Template Resolution
SHALL resolve `.chezmoi.yaml.tmpl` variables during add/apply.

#### Scenario: Identity placeholders
- GIVEN template defines `{{ .name }}`, `{{ .email }}`
- WHEN files with template vars are processed
- THEN placeholders resolved from template

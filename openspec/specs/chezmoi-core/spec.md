# chezmoi-core Spec
Init, apply workflow, ignore rules, rollback.

## Requirements
- **R1** (MUST): Init source dir at `~/.local/share/chezmoi` with `dot_config/` convention AND `.chezmoi.yaml.tmpl` containing identity placeholders (`{{ .name }}`, `{{ .email }}`).
- **R2** (MUST): Review `chezmoi diff` before every `chezmoi apply`.
- **R3** (MUST): `.chezmoiignore` excludes `dms/*.kdl`, `fish_variables`, `misconfig/`.
- **R4** (SHOULD): Btrfs snapshot before first apply.
- **R5** (MUST): Programmatic `chezmoi add` (first-time, empty tree) and `chezmoi re-add` (updated files) via skills.
- **R6** (MUST): Pre-commit validation via domain-specific validators (e.g., `ghostty +validate-config`) before every commit.

## Scenarios
- **S1**: GIVEN no source dir — WHEN `chezmoi init` — THEN `dot_config/` ready AND `.chezmoi.yaml.tmpl` created with identity placeholders.
- **S2**: GIVEN modified file — WHEN `chezmoi apply --dry-run` — THEN diffs shown, nothing written.
- **S3**: GIVEN DMS writes `dms/config.kdl` — WHEN `chezmoi add` — THEN skipped per ignore.
- **S4**: GIVEN first apply — WHEN `chezmoi apply` — THEN snapshot exists for rollback.
- **S5**: GIVEN pending changes — WHEN `chezmoi diff` — THEN all deltas displayed.
- **S6**: GIVEN skill requests config tracking — WHEN `chezmoi add` or `chezmoi re-add` runs — THEN file added/updated with `dot_` prefix before commit.
- **S7**: GIVEN config staged — WHEN validator runs (e.g., `ghostty +validate-config`) — THEN commit proceeds on success, blocked with error on failure.

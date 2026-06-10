# git-config Spec
Per-machine git identity, aliases, global gitignore.

## Requirements
- **R1** (MUST): Set `user.name` + `user.email` in `~/.gitconfig`. MAY template by hostname.
- **R2** (SHOULD): Include aliases (`co=checkout`, `st=status`).
- **R3** (SHOULD): Track global gitignore via `core.excludesfile`.

## Scenarios
- **S1**: GIVEN laptop apply — WHEN `git config --global user.name` — THEN laptop identity.
- **S2**: GIVEN PC apply — WHEN `git config --global user.email` — THEN PC email.
- **S3**: GIVEN git-config applied — WHEN `git st` — THEN runs `git status`.
- **S4**: GIVEN gitignore tracked — WHEN `git config core.excludesfile` — THEN points to file.

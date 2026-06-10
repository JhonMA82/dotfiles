# launcher-config Spec
DMS launcher env variables. Auto-generated configs excluded.

## Requirements
- **R1** (MUST): Track `~/.config/environment.d/90-dms.conf`.
- **R2** (MUST): Exclude `~/.config/niri/dms/` auto-gen files via `.chezmoiignore`.

## Scenarios
- **S1**: GIVEN apply runs — WHEN DMS starts — THEN env vars loaded from tracked `.conf`.
- **S2**: GIVEN DMS writes `niri/dms/panel.kdl` — WHEN `chezmoi add` — THEN skipped.
- **S3**: GIVEN both machines pull repo — WHEN DMS launched — THEN same env vars.

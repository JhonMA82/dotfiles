# niri-config Spec
Niri compositor with hostname-templated output/bind blocks.

## Requirements
- **R1** (MUST): `{{ if eq .chezmoi.hostname "laptop" }}` for per-machine blocks.
- **R2** (MUST): Render correct display output/resolution per hostname.
- **R3** (MUST): `niri validate config.kdl` exits zero before apply.

## Scenarios
- **S1**: GIVEN hostname=laptop — WHEN apply — THEN laptop output block only.
- **S2**: GIVEN hostname=main-pc — WHEN apply — THEN PC output block only.
- **S3**: GIVEN valid config — WHEN `niri validate` — THEN exit 0.
- **S4**: GIVEN broken template — WHEN `niri validate` — THEN non-zero, apply blocked.

# AGENTS.md — System & Hardware Specifications

Target environment for agents and AI assistants working on this machine.

## Operating System

- **Distribution**: CachyOS (Arch-based, rolling release)
- **Build ID**: rolling
- **Kernel**: `7.0.11-1-cachyos` — SMP PREEMPT_DYNAMIC, x86_64
- **Init/Service manager**: systemd
- **Bootloader**: Limine (UEFI)
- **Firmware mode**: UEFI x86_64 (64-bit firmware)
- **Display server**: Niri (Wayland) with DMS (Dynamic Menu Shell)
- **Audio**: PipeWire
- **Package manager**: pacman + AUR helpers (paru/yay)

## Filesystem Layout

- **Type**: btrfs on a single partition (`/dev/sda2`)
- **Subvolumes**:
  - `@` → `/` (subvolid 256)
  - `@home` → `/home` (subvolid 257)
  - `@srv` → `/srv` (subvolid 259)
  - `@log`, `@pkg`, `@.snapshots` (CachyOS defaults)
- **Mount options**: `rw,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2`
- **Snapshots**: snapper + btrfs snapshots (rollback-friendly)

## Hardware

- **Vendor/Model**: Acer Aspire R3-431T
- **CPU**: Intel Celeron 3205U @ 1.50 GHz (Broadwell-U, 2 cores / 2 threads)
- **Cache**: 2048 KB L2
- **RAM**: 3.7 GiB DDR3 (low — design accordingly)
- **GPU**: Intel Broadwell-U GT1 [HD Graphics] (integrated, rev 08)
- **Ethernet**: Realtek RTL8111/8168/8211/8411 PCIe Gigabit (rev 0c)
- **Wi-Fi**: Qualcomm Atheros QCA9565 / AR9565 (rev 01)
- **Storage**: ADATA SU630 223.6 GiB SSD (SATA, TRIM/discard active)
- **Swap**: zram0 (3.7 GiB)

## Working Directory

- **Default cwd for agents**: `/home/juan/misconfig`
- **Owner**: user `juan` (non-root, passwordless sudo expected)

## Agent Notes (must read before acting)

1. **Low memory** (~3.7 GiB total). Do NOT spawn heavy build chains (cargo, large npm installs, electron builds) without checking RAM headroom. Prefer small, incremental operations.
2. **btrfs + noatime + zstd** — be aware of CoW behavior; do not run full-disk operations against `/` without snapshots.
3. **Rolling release** — kernel and userland move together; pin or test before assuming versions match older docs.
4. **UEFI + Limine** — boot loader entries live in the ESP; kernel cmdline edits go through Limine config, not GRUB.
5. **Niri is a scrollable-tiling Wayland compositor** — global shortcuts and screen layout differ from Sway/Hyprland; do not assume i3/Sway config syntax.
6. **No GPU acceleration to spare** (Intel HD Graphics Broadwell). Avoid anything requiring CUDA/ROCm/VA-API beyond Broadwell's light Quick Sync profile.
7. **Wi-Fi driver** for QCA9565/AR9565 is `ath9k` — well supported but watch for regulatory domain on 5 GHz.
8. **Path conventions**: user code, dotfiles, and project repos live under `/home/juan`. System config edits typically require `sudo` or `pkexec`.

## Config Automation (cfg)

- Use `cfg` skill to manage dotfiles: "change ghostty theme", "add fzf to fish"
- Skills: cfg (orchestrator), cfg-chezmoi (versioning), cfg-ghostty, cfg-yazi, cfg-niri, cfg-bootstrap
- Validation before commit is mandatory
- All changes versioned via chezmoi in `chezmoi/` (unified repo)

### MANDATORY: Every config change goes through cfg

When the user mentions ANY dotfile, config file, or tool setup (niri, ghostty, yazi, fish, git, alacritty, dms, waybar, pipewire, etc.), you MUST:

1. Load the `cfg` skill FIRST
2. Check if `cfg-{domain}` exists
3. If it exists → delegate to it
4. If it doesn't → offer to create it, THEN delegate
5. NEVER run `chezmoi add` or edit `~/.config/` directly without cfg

This applies to ANY phrasing: "subí la config de X", "agregá X al repo", "quiero versionar X", "cambiá X de Y", etc.

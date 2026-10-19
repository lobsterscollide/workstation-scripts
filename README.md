# workstation-scripts

> A tiered security routine for a single-user Arch Linux workstation — a one-minute daily check up to a quarterly audit.

[![CI](https://github.com/lobsterscollide/workstation-scripts/actions/workflows/ci.yml/badge.svg)](https://github.com/lobsterscollide/workstation-scripts/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## The idea

Security hygiene only happens if it's cheap enough to do. These scripts split it into tiers by how
long they take, so the fast check actually runs every session and the slow ones have a clear
trigger. Each tier ends with one summary: what's fine, what needs attention, and the exact command
to fix it. Work lives on LUKS-encrypted volumes that are opened and closed on demand, and backups go
to an encrypted external drive with restic.

## What's inside

| Path | What it is |
|------|------------|
| `bin/startup` | Every session, <1 min: boot health, VPN up, pending updates, hardened-api posture, encrypted volumes |
| `bin/scan` | Often / after anything odd, ~5–10 min: rkhunter, chkrootkit, targeted ClamAV, AIDE, SUID/SGID audit, SSH keys |
| `bin/fullscan` | Overnight / before pushing to other machines: whole-filesystem malware, rootkit and integrity scan |
| `bin/audit` | Quarterly / before touching a client system, 30–60 min: full Lynis, full ClamAV, credential exposure, listening services, hardened-api report, package delta |
| `bin/update` | When ready, 15–30 min: pacman + mise, keep `linux-hardened` as boot default, arch-audit, signature and baseline refresh |
| `bin/luks-setup` | One-time: create encrypted `source` (50G) and `secrets` (2G) volumes |
| `bin/unlock`, `bin/lock` | Open / close those volumes |
| `bin/backup-open`, `bin/backup-run`, `bin/backup-close` | restic backup to an encrypted external drive |
| `bin/lynis-audit`, `bin/scan-logs` | Run Lynis into the log folder; browse and tail scan logs |
| `bin/shortcut` | Print every Hyprland keybinding (Omarchy layout), grouped |
| `lib/syscheck.sh` | Shared output, progress and logging helpers |

## Quick start

Run straight from a clone:

```sh
./bin/startup
```

Or install onto your `PATH`:

```sh
install -m 0755 bin/* ~/.local/bin/
install -D -m 0644 lib/syscheck.sh ~/.local/lib/syscheck.sh
```

## How it works

Each check script sources `lib/syscheck.sh` (found relative to the script, so both layouts work),
prints a progress bar per step, tees a colour-stripped copy to
`~/.local/var/log/security/<name>-<timestamp>.log`, and finishes with a summary of errors and
items needing attention.

Settings (env):

| Variable | Used by | Default |
|----------|---------|---------|
| `HARDENED_API_KEY` | `startup`, `audit`, `update` — read posture from [hardened-api](https://github.com/lobsterscollide/hardened-api) | — |
| `HARDENED_API_HARDEN_KEY` | `update` — refresh the AIDE baseline | falls back to `HARDENED_API_KEY` |
| `HARDENED_API_URL` | as above | `http://localhost:8080` |
| `BACKUP_UUID` | `backup-open` (or pass the device as an argument) | — |

Backups need a restic password file at `/mnt/secrets/restic.pass`. `backup-run` backs up
`/mnt/source`, `/mnt/secrets` and `/etc`, then keeps 7 daily, 4 weekly and 3 monthly snapshots.

## Requirements

- Arch Linux with `linux-hardened` and the Limine bootloader (Omarchy's default) — `update` edits
  `/boot/limine.conf` to keep `linux-hardened` as the default entry
- Tools used when present: lynis, clamav, rkhunter, chkrootkit, aide, arch-audit, restic,
  cryptsetup, mise; `curl` and `python3` for the hardened-api integration
- `sudo`

## Security notes

- Scan logs go to `~/.local/var/log/security/` with owner-only permissions. They describe your
  system's weak spots — keep them private.
- API keys are passed to `curl` on stdin, never as command-line arguments (which other users can
  see in `ps`).
- `restic.pass` is backed up *inside* the encrypted repository, so keep a second copy somewhere
  else (e.g. a password manager) or you cannot restore.
- `luks-setup` overwrites existing volume images after an explicit `YES` confirmation.

## Status

Complete and shared as a reference; not actively maintained.

## Part of a set

| Project | What it is |
|---------|------------|
| [railed](https://github.com/lobsterscollide/railed) | Operating discipline for AI agents with real tool access, built from documented failures |
| [hardened-api](https://github.com/lobsterscollide/hardened-api) | Linux hardening checks and fixes as an API an agent can drive |
| [usb-triage](https://github.com/lobsterscollide/usb-triage) | Run-from-USB security audit for Linux, macOS and Windows |
| **workstation-scripts** | Daily → quarterly security routine for an Arch workstation |
| [a2a-schemas](https://github.com/lobsterscollide/a2a-schemas) | Permission boundaries and handoffs between a "build" agent and an "apply" agent |

## License

[MIT](LICENSE)

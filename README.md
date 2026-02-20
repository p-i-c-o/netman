# netman

Minimal DNS profile switcher.

## Quick start

```bash
./netman --test set home
./netman --test
./netman set school
```

- `--test` writes to `DEMO` under `NETMAN_HOME` (safe mode).
- Normal mode writes to `/etc/resolv.conf`.

## Commands

```bash
netman [--test] [--json]
netman [--test] [--json] set <profile>
netman [--test] [--json] list
netman [--test] [--json] edit <profile>
netman [--test] [--json] create <name> --dns <ip> [--dns <ip> ...] [--subnet <cidr>]
netman [--test] [--json] rollback
```

### Behavior

- `netman` shows current matched profile (or `custom/unknown`).
- `netman set <profile>` applies that profile.
- On successful swap, output is:
  - `Swapped to X.X.X.X/YY subnet.`
  - In test mode: `[TEST] Swapped to X.X.X.X/YY subnet.`

## Profile format

Each file in `profiles/` is a profile. Example:

```conf
# Written by netman
# home profile
# subnet 192.168.1.0/24

nameserver 192.168.1.1
nameserver 1.1.1.1
```

- Subnet is parsed from any `X.X.X.X/YY` text (commonly via `# subnet ...`).
- If not found, subnet output becomes `unknown`.

## Profile management

### List profiles

```bash
./netman list
```

### Edit a profile

```bash
EDITOR=nvim ./netman edit home
```

Creates the profile file if missing.

### Create a profile

```bash
./netman create office --dns 1.1.1.1 --dns 8.8.8.8 --subnet 10.20.0.0/16
```

Requires at least one `--dns`.

## Rollback

`netman` stores rotating backups before each apply, then restores latest backup with rollback.

```bash
./netman rollback
./netman --test rollback
```

- Backup directory default: `$NETMAN_HOME/backups`
- Max backups kept per mode: `5` (`live-*` and `test-*`)

## Installation

From this package folder:

```bash
sudo ./install.sh --user "$(logname)"
```

This installs:

- `netman` launcher in `/usr/local/bin/netman`
- app files in `/usr/local/share/netman`
- completions (bash/zsh when possible)
- optional passwordless sudo helper (`/usr/local/sbin/netman-apply`)

Non-root/local install:

```bash
./install.sh --prefix "$HOME/.local" --skip-passwordless
```

## JSON mode

Add `--json` for machine-readable output.

Examples:

```bash
./netman --json
./netman --json list
./netman --json create lab --dns 9.9.9.9 --subnet 10.50.0.0/16
./netman --json --test set school
./netman --json rollback
```

Sample output:

```json
{"action":"swap","profile":"school","subnet":"10.42.0.0/16","test":true}
```

## Shell completions

If you used `install.sh`, completion files are installed automatically when target directories exist.

Manual setup examples:

### Bash

```bash
source ./completions/netman.bash
```

### Zsh

```bash
fpath=("$PWD/completions" $fpath)
autoload -Uz compinit && compinit
```

## Environment variables

- `NETMAN_HOME` (default: directory containing `netman` script)
- `NETMAN_CONFIG_DIR` (default: `$NETMAN_HOME/profiles`)
- `NETMAN_RESOLV_CONF` (default: `/etc/resolv.conf`)
- `NETMAN_APPLIER_CMD` (default: `/usr/local/sbin/netman-apply`)
- `NETMAN_BACKUP_DIR` (default: `$NETMAN_HOME/backups`)
- `NETMAN_BACKUP_LIMIT` (default: `5`)
- `EDITOR` for `netman edit`

## Notes

- Without elevated permissions (or passwordless setup), direct writes to `/etc/resolv.conf` will fail.
- Use `--test` whenever you want safe, local-only changes.

# netman

> manual networking tool since I was too lazy to fix system network daemon


<p align="center">
  <img alt="Status" src="https://img.shields.io/badge/Status-In%20Progress-blue">
  <img alt="Category" src="https://img.shields.io/badge/Category-Software-0366d6">
  <img alt="Version" src="https://img.shields.io/badge/Version-0.1.0-orange">
  <img alt="Updated" src="https://img.shields.io/badge/Updated-2026--02--20-brightgreen">
</p>



## Overview
- **Goal:** Simple management of the `/etc/resolv.conf` file
- **Why:** DNS resolution was breaking when changing networks 
- **Scope:** Simple profile setting
- **Out of scope:** Dynamic / automatic changing

## Highlights
- Allows users to define custom profiles
- JSON output for scripting or wrappers

## Quick Start
1. Download the [latest](https://github.com/p-i-c-o/netman/releases/tag/latest) release
2. Install the script using:
```bash
sudo ./install.sh --user "$(logname)"
```
This installs:

- `netman` launcher in `/usr/local/bin/netman`
- App files in `/usr/local/share/netman`
- Completions (bash/zsh when possible)
- Optional passwordless sudo helper ( `/usr/local/sbin/netman-apply` )

## Usage
```shell
netman [--test] [--json]
netman [--test] [--json] set <profile>
netman [--test] [--json] list
netman [--test] [--json] edit <profile>
netman [--test] [--json] create <name> --dns <ip> [--dns <ip> ...] [--subnet <cidr>]
netman [--test] [--json] rollback
```

## Example Usage

```shell
# List all saved profiles
netman list

# Switch to a profile
netman set home

# Create a new profile with multiple DNS servers
netman create school --dns 1.1.1.1 --dns 8.8.8.8 --subnet 192.168.1.0/24

# Edit an existing profile
netman edit school

# Test a change without applying it
netman --test set school

# Output results as JSON (useful for scripts)
netman --json list

# Roll back to the previous profile
netman rollback
```

## Example Workflow
```shell
# 1) Create profiles
netman create home --dns 192.168.1.1 --dns 1.1.1.1 --subnet 192.168.1.0/24
netman create hotspot --dns 8.8.8.8 --dns 8.8.4.4 --subnet 192.168.43.0/24

# 2) See what exists
netman list

# 3) Switch networks
netman set hotspot

# 4) If something breaks, restore previous settings
netman rollback
```


## Roadmap
- [ ] More beautiful UI

## License
MIT
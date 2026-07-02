# Advanced Setup

PhoneCode has two setup paths:

1. Interactive installer: `scripts/install.sh`
2. Compatibility wrapper: `scripts/setup.sh`

`setup.sh` now forwards to `install.sh` so old instructions still work.

## Run the Installer

```sh
sh scripts/install.sh
```

Profiles:

```sh
sh scripts/install.sh --recommended
sh scripts/install.sh --minimal
sh scripts/install.sh --custom
sh scripts/install.sh --repair
sh scripts/install.sh --uninstall
```

Preview without writing files:

```sh
sh scripts/install.sh --dry-run --profile minimal
```

## What Gets Installed

Depends on the selected profile. Recommended includes:

- Termux tools: `proot-distro`, `git`, `curl`, `openssh`, `nano`, `tmux`
- Ubuntu packages: Git, curl, build tools, jq, Python, tmux
- Node.js LTS through nvm
- Optional npm CLIs: OpenCode, Vercel, Neon
- Optional code-server
- PhoneCode commands: `phonecode`, `pc`, `ocode`
- Recommended `oa` shortcut for `ocode --auto`

## Custom Setup

Custom setup lets users opt in or out of:

- Ubuntu/proot-distro
- tmux config
- Node.js LTS
- code-server
- F5 open-app behavior
- OpenCode
- GitHub CLI
- Vercel CLI
- Neon CLI
- `oa` shortcut

Skipping Ubuntu/proot-distro also skips the Ubuntu-side helpers and tools.

F5 behavior is intentionally optional.

## Command Design

Readable:

```sh
phonecode doctor
phonecode code .
phonecode opencode
phonecode uninstall
```

Short:

```sh
pc doctor
pc code .
pc opencode
pc uninstall
```

OpenCode:

```sh
opencode          # official OpenCode, untouched
ocode             # safe wrapper
ocode --auto      # safe wrapper with auto mode
oa                # short shortcut for ocode --auto
```

## Backups

Before modifying user files, PhoneCode creates timestamped backups such as:

```text
~/.bashrc.phonecode.bak.YYYYMMDD-HHMMSS
~/.tmux.conf.phonecode.bak.YYYYMMDD-HHMMSS
```

## Uninstall

```sh
pc uninstall
```

Uninstall removes only PhoneCode-owned files, the PhoneCode block in `.bashrc`, and the Termux `start` command if PhoneCode owns it. It does not remove projects.

# Getting Started

Set up a phone-first development environment with Termux, Ubuntu, tmux, Node.js, code-server, and service CLIs.

## Fast Path

Use the interactive installer:

```sh
curl -fsSL https://raw.githubusercontent.com/rexroze/phonecode/main/scripts/install.sh -o install.sh
sh install.sh
```

Choose **Recommended**, **Minimal**, or **Custom**. Use Custom if you do not want optional features like F5 behavior, Vercel CLI, Neon CLI, or the `oa` shortcut.

After setup:

```sh
start
pc doctor
pc help
```

## Requirements

- Android phone with at least 8 GB free storage
- 6 GB RAM or more recommended
- Termux from F-Droid or GitHub releases, not the Play Store build
- A hardware keyboard helps, but is not required

During long installs, keep Termux in the foreground and disable battery saver for Termux.

## Manual Setup

Manual setup is still supported if you do not want the installer.

### Termux

```sh
pkg update && pkg upgrade
pkg install proot-distro git curl openssh nano tmux
```

Optional Android shared storage access:

```sh
termux-setup-storage
```

Keep projects inside Ubuntu's home directory when possible. Android shared storage is slower and can cause permission problems.

### Ubuntu

```sh
proot-distro install ubuntu
proot-distro login ubuntu
```

Inside Ubuntu:

```sh
apt update && apt upgrade
apt install git curl ca-certificates build-essential nano jq tmux python3
mkdir -p ~/projects
```

Use `apt` inside Ubuntu. Use `pkg` only in Termux.

### Start Command

Create a Termux command named `start` so Ubuntu is one word away:

```sh
cat > "$PREFIX/bin/start" << 'EOF'
#!/bin/sh
exec proot-distro login ubuntu -- bash -i
EOF
chmod +x "$PREFIX/bin/start"
```

From Termux, run:

```sh
start
```

Use `exit` to return from Ubuntu to Termux.

## PhoneCode Commands

The installer creates these commands inside Ubuntu:

```sh
phonecode doctor
pc doctor
pc code .
ocode --auto
```

`phonecode` is the readable command. `pc` is the short command. `ocode` is the safe OpenCode wrapper.

## tmux

```sh
cat > ~/.tmux.conf << 'EOF'
set -g mouse on
set -g history-limit 5000
set -g base-index 1
setw -g pane-base-index 1
EOF
```

Reload:

```sh
tmux source-file ~/.tmux.conf
```

## Git

```sh
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
git config --global init.defaultBranch main
git config --global credential.helper cache
```

Install GitHub CLI if needed:

```sh
apt install gh
```

Authenticate:

```sh
gh auth login
```

## Node.js

```sh
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
```

Close and reopen Ubuntu, then:

```sh
nvm install --lts
nvm use --lts
corepack enable
```

## code-server

Install code-server:

```sh
curl -fsSL https://code-server.dev/install.sh | sh
```

With PhoneCode helpers:

```sh
pc code .
```

or:

```sh
code .
```

Local mode binds to `127.0.0.1`. LAN mode requires password auth:

```sh
pc code lan .
```

## Open URLs From Ubuntu

```sh
open http://127.0.0.1:3000
```

or:

```sh
pc open http://127.0.0.1:3000
```

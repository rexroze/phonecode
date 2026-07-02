# Installer

PhoneCode now has an interactive installer that asks what you want first, then runs the install with a clear step display.

## Recommended Install

```sh
curl -fsSL https://raw.githubusercontent.com/rexroze/phonecode/main/scripts/install.sh -o install.sh
sh install.sh
```

Safer inspect-first install:

```sh
curl -fsSL https://raw.githubusercontent.com/rexroze/phonecode/main/scripts/install.sh -o install.sh
less install.sh
sh install.sh
```

The installer shows the PhoneCode phone banner, asks for an install type, summarizes choices, then runs the selected steps.
Interactive terminals get color when supported; logs and dumb terminals stay plain.

## Install Types

| Type | Use it when |
| --- | --- |
| Recommended | You want the normal phone-first web dev setup. |
| Minimal | You only want the basics and no extra CLIs. |
| Custom | You want to choose each tool. |
| Repair | You already installed PhoneCode and want to restore helpers. |
| Dry run | You want to preview without changing files. |
| Uninstall | You want to remove PhoneCode-owned files. |

## Recommended Profile

Installs or configures:

- Ubuntu through `proot-distro`
- tmux
- Node.js LTS through nvm
- code-server
- `phonecode` command
- `pc` shortcut
- `ocode` safe OpenCode wrapper
- `oa` shortcut for `ocode --auto`
- OpenCode
- GitHub CLI
- Vercel CLI
- Neon CLI

F5 open-app behavior stays optional because not everyone wants F5 changed.

## Minimal Profile

Installs or configures:

- Ubuntu through `proot-distro`
- tmux
- Node.js LTS through nvm
- `phonecode` command
- `pc` shortcut
- `phonecode doctor`

It skips code-server, F5 behavior, OpenCode, GitHub CLI, Vercel CLI, and Neon CLI.

## Custom Profile

Custom setup asks about:

```text
Ubuntu/proot-distro setup
tmux config
Node.js LTS
code-server
F5 open-app behavior
OpenCode
GitHub CLI
Vercel CLI
Neon CLI
oa shortcut for ocode --auto
```

If you skip Ubuntu/proot-distro setup in Custom mode, PhoneCode skips Ubuntu-side helpers and tools too.

This is the best choice if you do not want the F5 behavior or do not need Vercel/Neon yet.

## Non-interactive Package Installs

PhoneCode asks for choices up front, then tries to avoid random package prompts.

In Ubuntu, it uses:

```sh
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold"
```

In Termux, it uses `pkg update -y`, `pkg upgrade -y`, and `pkg install -y` where supported.
Package config-file prompts are handled non-interactively by keeping the current
local config file, matching the default answer Termux shows for those prompts.

Some package-manager prompts can still appear on unusual systems. If that happens, PhoneCode should show the current step and the log path so the prompt is not confusing.

## Progress UI

The installer uses step-based progress instead of fake exact package progress.
During a normal interactive install, package-manager output is written to the log
and the terminal keeps one compact status line visible. That line is redrawn in
place so narrow phone terminals do not fill with repeated progress rows.

Example:

```text
PhoneCode is installing...
[1/7] Updating Termux packages 14%
[2/7] Installing Termux tools 28%
[3/7] Installing Ubuntu if needed 42%
```

The progress means "which setup phase are we in," not exact download progress.
If something fails, check the log path printed near the start of the install.

## Commands After Install

```sh
start
pc doctor
pc help
mkdir -p ~/projects/my-app
cd ~/projects/my-app
code .
oa
```

## Uninstall

```sh
pc uninstall
```

or from Termux:

```sh
sh scripts/install.sh --uninstall
```

Uninstall removes only PhoneCode-owned files:

```text
PhoneCode .bashrc block
~/.local/bin/phonecode
~/.local/bin/pc
~/.local/bin/ocode
~/.local/bin/oa
~/.local/share/phonecode
$PREFIX/bin/start if PhoneCode owns it
/tmp/phonecode-*
```

It does not delete `~/projects` or user repos.

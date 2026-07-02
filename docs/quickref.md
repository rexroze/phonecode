# PhoneCode Quick Reference

## Setup

| Task | Command |
| --- | --- |
| Interactive setup | `sh scripts/install.sh` |
| Recommended setup | `sh scripts/install.sh --recommended` |
| Minimal setup | `sh scripts/install.sh --minimal` |
| Custom setup | `sh scripts/install.sh --custom` |
| Dry run | `sh scripts/install.sh --dry-run` |
| Uninstall | `sh scripts/install.sh --uninstall` |

## Daily Commands

| Task | Command |
| --- | --- |
| Enter Ubuntu | `start` |
| Exit Ubuntu | `exit` |
| Help | `pc help` or `phonecode help` |
| Diagnostics | `pc doctor` |
| Open editor | `code .` or `pc code .` |
| List editors | `code ls` or `pc code ls` |
| Stop editor | `code stop 1` or `pc code stop 1` |
| Stop all editors | `code stop` or `pc code stop` |
| LAN editor | `code lan .` or `pc code lan .` |
| Show password | `pc password` |
| Open URL | `open http://127.0.0.1:3000` |

## OpenCode

| Task | Command |
| --- | --- |
| Normal OpenCode | `opencode` |
| Normal OpenCode auto | `opencode --auto` |
| Safe OpenCode | `ocode` |
| Safe OpenCode auto | `ocode --auto` |
| Short auto shortcut | `oa` |

Recommended:

```sh
mkdir -p ~/projects/my-app
cd ~/projects/my-app
oa
```

Avoid:

```sh
cd /root
opencode --auto
```

Starting OpenCode from `/root`, `~`, or `~/projects` can make it scan too much and feel slow.

## PhoneCode Command

Readable command:

```sh
phonecode doctor
phonecode code .
phonecode opencode
phonecode uninstall
```

Short command:

```sh
pc doctor
pc code .
pc opencode
pc uninstall
```

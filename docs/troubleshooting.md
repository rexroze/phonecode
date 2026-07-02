# Troubleshooting

Problems usually belong to one layer: Android, Termux, Ubuntu/proot, tmux, code-server, Node.js, GitHub, Vercel, Neon, or OpenCode.

Start with:

```sh
pc doctor
```

## Android Kills Processes

Symptoms:

- Dev server stops when switching apps
- Long installs fail with screen off
- tmux session disappears after leaving Termux

Fix:

- Disable battery optimization for Termux.
- Keep screen on during installs.
- Commit before switching apps.
- Detach tmux before switching apps, but remember tmux cannot survive Android killing Termux.

## Installer Prompts Too Much

Use the interactive installer so choices are collected before package installation:

```sh
sh scripts/install.sh
```

For preview:

```sh
sh scripts/install.sh --dry-run --profile minimal
```

PhoneCode uses non-interactive package options where possible, but some package managers can still ask on unusual systems. Check the log path printed by the installer.

## Repair PhoneCode Helpers

```sh
sh scripts/install.sh --repair
```

or, if PhoneCode is already installed:

```sh
pc doctor
```

## Uninstall

```sh
pc uninstall
```

Uninstall removes PhoneCode-owned helpers only. It does not delete `~/projects`.

## Termux Packages

```sh
pkg update && pkg upgrade
```

If downloads fail, run:

```sh
termux-change-repo
```

Make sure Termux is from F-Droid or GitHub, not Play Store.

## proot-distro

```sh
proot-distro list
proot-distro login ubuntu
```

If Ubuntu is missing:

```sh
proot-distro install ubuntu
```

If a tutorial needs systemd, kernel modules, or Docker, it will not work normally in proot.

## Node.js / npm

```sh
node --version && npm --version && which node
```

If using nvm and versions are wrong:

```sh
source ~/.bashrc
nvm use --lts
```

Reinstall deps only when needed:

```sh
rm -rf node_modules package-lock.json
npm install
```

This is slow on phones, so avoid doing it repeatedly.

## code-server

Start local-only:

```sh
pc code .
```

List sessions:

```sh
pc code ls
```

Stop one session:

```sh
pc code stop 1
```

Stop all sessions:

```sh
pc code stop
```

If another device must connect over Wi-Fi, use explicit LAN mode only on a trusted private network:

```sh
pc code lan .
```

Stop it when finished:

```sh
pc code stop
```

## OpenCode Feels Laggy

Do not run OpenCode from `/root`, `~`, or the whole `~/projects` folder.

Recommended:

```sh
mkdir -p ~/projects/my-app
cd ~/projects/my-app
oa
```

Normal OpenCode still works:

```sh
opencode --auto
```

Check where OpenCode is running:

```sh
pgrep opencode
readlink -f /proc/<PID>/cwd
```

Or:

```sh
pc doctor
```

If OpenCode is running from a broad folder, stop it and restart from a specific project.

## GitHub Push

```sh
git remote -v && git status
```

For HTTPS, confirm your token is valid. For SSH:

```sh
ssh -T git@github.com
```

## Vercel Deploy

```sh
vercel logs
vercel env ls
```

Check the first build error. Confirm env vars are set. Test locally with:

```sh
npm run build
```

## Neon Connection

Check local env var without revealing it:

```sh
test -n "$DATABASE_URL" && echo "DATABASE_URL is set"
```

Never paste real connection strings into issues, READMEs, or chat.

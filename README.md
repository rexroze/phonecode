# PhoneCode

```text
        ______________________
       /  __________________  \
      |  |                  |  |
      |  |   phonecode      |  |
      |  |   >_ build       |  |
      |  |   >_ ship        |  |
      |  |__________________|  |
       \______  ____  ______/
              \/    \/

          code from your phone
          Termux -> Ubuntu -> code
```

Build, edit, run, and deploy small web apps from an Android phone.

PhoneCode is a practical phone-first development workflow. It uses Termux, Ubuntu through `proot-distro`, code-server, tmux, OpenCode, GitHub CLI, Vercel CLI, and Neon CLI to make a phone usable for learning, prototypes, maintenance work, and small production apps.

It is not trying to turn Android into a laptop. The goal is a clear workflow that respects phone limits: small screens, slower installs, Android background process kills, and the limits of `proot`.

```text
Android
  -> Termux
  -> Ubuntu in proot-distro
  -> tmux, code-server, OpenCode
  -> GitHub
  -> Vercel and Neon
```

## Recommended Install

The fastest path is the interactive installer:

```sh
curl -fsSL https://raw.githubusercontent.com/rexroze/phonecode/main/scripts/install.sh -o install.sh
sh install.sh
```

The installer lets you choose **Recommended**, **Minimal**, **Custom**, **Repair**, **Dry run**, or **Uninstall**. It asks for choices first, then installs with a clear step display instead of random prompts.

After setup:

```sh
start
pc doctor
cd ~/projects/my-app
code .
ocode --auto
```

## Command Design

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

OpenCode commands:

```sh
opencode          # official OpenCode, untouched
opencode --auto   # official OpenCode auto mode, untouched
ocode             # PhoneCode-safe OpenCode wrapper
ocode --auto      # safe OpenCode with auto mode
oa                # optional shortcut for ocode --auto
```

`ocode` refuses to start OpenCode from broad folders like `/root`, `~`, or `~/projects`, because that can make OpenCode scan too much and feel laggy. Use it inside one project folder.

## What You Get

- Interactive setup with Recommended, Minimal, Custom, Repair, Dry run, and Uninstall flows
- A repeatable setup path for Termux and Ubuntu on Android
- A browser-based editor with `code .`
- A one-command way to open local app URLs from Ubuntu
- Optional F5 behavior in code-server for framework apps and plain HTML projects
- tmux guidance for keeping a phone terminal usable
- OpenCode guidance with safe project-folder wrappers
- A `phonecode doctor` / `pc doctor` command for diagnostics
- A first-app path from local edit to GitHub push to Vercel deploy
- Backups before PhoneCode modifies user config files

## Who This Is For

PhoneCode is useful if you want to:

- Learn web development from an Android phone
- Build and deploy small apps without buying a laptop first
- Maintain simple projects while away from a desktop
- Experiment with AI coding agents in a mobile terminal
- Understand what works well on a phone before depending on it

Use a laptop or remote development machine for heavy builds, Docker-based projects, large monorepos, high-risk production migrations, or work that needs full Linux kernel features.

## Toolchain

| Layer | Tool | Purpose |
| --- | --- | --- |
| Phone terminal | Termux | Android shell and package manager |
| Linux userland | Ubuntu via `proot-distro` | Familiar Linux environment without a full VM |
| Terminal workspace | tmux | Keep panes and sessions manageable on a phone |
| Editor | code-server | VS Code in the phone browser |
| Runtime | Node.js LTS via nvm | Next.js and common web tooling |
| AI help | OpenCode by default | Terminal coding agent for lower-typing workflows |
| Source control | Git and GitHub CLI | Commit, authenticate, create repos, push |
| Deploy | Vercel CLI | Ship web apps from the terminal |
| Database | Neon CLI | Add hosted PostgreSQL when the app needs it |

## Docs

1. **[Installer](docs/installer.md)** - Interactive setup, profiles, repair, and uninstall.
2. **[Getting Started](docs/getting-started.md)** - Manual setup and first checks.
3. **[Quick Reference](docs/quickref.md)** - Daily command cheat sheet.
4. **[Terminal Multiplexer](docs/terminal-multiplexer.md)** - Run editor, dev server, and commands together.
5. **[Create Your First App](docs/create-first-app.md)** - Build, run, push, and deploy a small app.
6. **[AI Coding Agents](docs/ai-agents.md)** - Use OpenCode safely inside one project.
7. **[Advanced Setup](docs/advanced-setup.md)** - Scripted install details and customization.
8. **[Troubleshooting](docs/troubleshooting.md)** - Fixes for Android, Termux, proot, Node.js, code-server, GitHub, Vercel, and Neon.

## Daily Workflow

Inside Ubuntu:

```sh
cd ~/projects/my-app
code .
npm run dev
open http://127.0.0.1:3000
```

Use the safe OpenCode wrapper from inside the project:

```sh
ocode --auto
```

Before pushing:

```sh
npm run lint
npm run build
git diff
git status
```

Use `tmux` to keep the editor and dev server running together. Commit often because Android can stop background work.

## Realistic Limits

- Android may kill Termux or local servers when you switch apps or turn the screen off.
- `proot-distro` is not a full VM. Docker, systemd, kernel modules, and some native tooling will not work normally.
- Installs and builds are slower than on a laptop.
- code-server in a phone browser is good for editing, but it is not desktop VS Code with full browser debugging.
- Hosted services change auth flows, free tiers, and CLI behavior. Check current service docs when output differs.
- Keep secrets out of prompts, screenshots, READMEs, and Git history.

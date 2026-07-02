# AI Coding Agents

AI coding agents help on a phone because they reduce typing. PhoneCode uses OpenCode as the default terminal agent.

## Recommended: OpenCode

Install through the PhoneCode installer, or manually:

```sh
npm install -g opencode-ai
```

Verify:

```sh
opencode --version
```

## Start OpenCode Inside One Project

Good:

```sh
cd ~/projects/my-app
opencode
```

Better with PhoneCode safety:

```sh
cd ~/projects/my-app
ocode --auto
```

Avoid running OpenCode from broad folders:

```sh
cd /root
opencode --auto
```

```sh
cd ~/projects
opencode --auto
```

When OpenCode starts from `/root`, `~`, or the whole `~/projects` folder, it may scan or watch too many files. On a phone, that can feel laggy.

## Safe OpenCode Wrapper

PhoneCode adds:

```sh
ocode
ocode --auto
```

`ocode` runs OpenCode, but refuses to start from broad folders like `/root`, `~`, or `~/projects`.

Normal OpenCode remains untouched:

```sh
opencode
opencode --auto
```

Optional shortcut:

```sh
oa
```

`oa` means:

```sh
ocode --auto
```

## Check Running OpenCode Sessions

```sh
pgrep opencode
readlink -f /proc/<PID>/cwd
```

Or use:

```sh
pc doctor
```

PhoneCode doctor warns if OpenCode is running from a broad folder.

## Review Habit

Before accepting or pushing agent work:

```sh
git diff
npm run lint
npm run build
git status
```

## Secrets

- Do not paste live secrets into prompts.
- Keep production credentials in Vercel/Neon env vars.
- Check before pushing: `git diff --cached`.

## Next Step

Continue with [Troubleshooting](troubleshooting.md) if something goes wrong.

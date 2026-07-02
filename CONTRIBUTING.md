# Contributing

Run checks before opening a PR:

```sh
sh -n scripts/install.sh
sh scripts/install.sh --dry-run --profile minimal --yes
sh tests/smoke.sh
```

If commands or setup behavior change, update the docs in the same PR.

Docs that commonly need updates:

- `README.md`
- `docs/installer.md`
- `docs/getting-started.md`
- `docs/advanced-setup.md`
- `docs/troubleshooting.md`
- `docs/ai-agents.md`
- `docs/quickref.md`

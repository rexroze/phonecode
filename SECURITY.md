# Security

PhoneCode can start code-server locally or on the LAN. Treat LAN mode carefully.

Safe defaults:

- `pc code .` binds to `127.0.0.1`.
- `pc code lan .` uses password auth.

Avoid:

- Do not expose code-server on public Wi-Fi.
- Do not use `--auth none` with `0.0.0.0`.
- Do not paste secrets into screenshots, prompts, issues, READMEs, or chat.
- Stop LAN sessions when finished: `pc code stop`.

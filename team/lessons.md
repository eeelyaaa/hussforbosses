# Huss for Bosses: lessons

One dated line each, one lesson per line: a playbook entry that helped or misled, a surprise from Studio, a tool or
instruction that got in the way. Suggestions for the whole team go to ro-team `vault/inbox/notes/`.

- 2026-11-25 (tech-lead, M0): the older Studio MCP's `run_code` fails with "invalid value (nil) ... for 'concat'" when `print` gets a nil argument; wrap values in `tostring`.
- 2026-11-25 (tech-lead, M0): prints from a module `require`d inside `run_code` don't come back in the `run_code` result; read them with `get_console_output`.
- 2026-11-25 (tech-lead, M0): `run_script_in_play_mode` returns only the server's log; a LocalScript's print was not in it nor in the console afterwards. Read client state through a reporting remote.
- 2026-11-25 (tech-lead, M0): DevSync works from the MCP with `HttpService.HttpEnabled` off in this place too (deja-kill's finding holds).

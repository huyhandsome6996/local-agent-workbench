---
name: windows-workstation
description: Use for safe multi-step Windows workstation tasks through Remote Desktop Commander or local Desktop Commander, PowerShell/CMD, Chrome DevTools MCP CLI, local files, processes and Git repositories.
---

# Windows Workstation Skill

## Select the correct bridge

- For ChatGPT Web, Claude Web and other hosted chat agents, use the **Remote Desktop Commander Remote** connector. Its endpoint is `https://mcp.desktopcommander.app/mcp`.
- The Windows device is paired by `npx @wonderwhy-er/desktop-commander@latest remote`. That terminal must stay open.
- For a local coding agent on the same machine, Desktop Commander local stdio is also valid.
- Never assume the connector is available just because this repository is present. Call a tool and verify the exact paired device is Online.

## Preflight

1. Confirm the paired device and its Online status.
2. Run harmless terminal checks for `$env:COMPUTERNAME`, `$env:USERPROFILE`, `node --version` and `git --version`.
3. For browser tasks, run `& "$env:APPDATA\npm\chrome-devtools.cmd" status` and `list_pages --output-format=json`.
4. Confirm the intended browser tab exists. If Chrome remote-debugging consent is missing, ask the user to enable/approve it manually.
5. Inspect project paths and Git state before changing files.

## Browser control through Chrome DevTools MCP

Chrome DevTools MCP is installed on the paired Windows PC. Web-based agents call its CLI through Remote Desktop Commander's terminal. Use the CLI path:

`$cli = Join-Path $env:APPDATA 'npm\chrome-devtools.cmd'`

Typical workflow:

1. `& $cli list_pages --output-format=json`
2. `& $cli take_snapshot <pageId>`
3. Find the exact element UID from the snapshot.
4. `click`, `fill`, `press_key` or `type_text` using the UID.
5. Take a fresh snapshot after navigation/state changes.
6. For visual verification: `& $cli take_screenshot <pageId> --filePath "$env:USERPROFILE\AgentWorkstation\workspace\after.png"`; read the saved image through Desktop Commander if needed.
7. Use `list_console_messages`, `list_network_requests`, `get_network_request` and `get_css_styles` for debugging.

Use DOM/accessibility UIDs as the default. Do not rely on terminal text alone when a browser screenshot or DOM snapshot can establish the result.

## Browser safety

- Chrome remote debugging requires a user-controlled setting and a manually approved Chrome permission dialog. Never bypass or automate consent.
- Only access the specific page/tab the user asked about. Do not inspect unrelated ChatGPT/Claude conversations, private messages, cookies, storage or credentials.
- Do not send messages, submit forms, publish or delete without explicit user instruction.
- Do not expose a DevTools debugging port publicly.

## PowerShell best practices

- Use `$ErrorActionPreference = 'Stop'` for scripts that should fail fast.
- Use explicit absolute paths and quote them.
- Back up existing files before replacement; use temporary files and atomic moves for important config updates.
- Preserve unrelated JSON/TOML keys.
- Never run as Administrator by default.
- Never modify Registry, services, firewall or Windows security settings without explicit authorization.
- Avoid wildcard deletion and recursive deletes unless explicitly requested.

## Multi-task workflow

1. Break complex tasks into independent workstreams.
2. Run independent read-only checks in parallel.
3. Do not write the same file concurrently.
4. Record PIDs for long-running processes and poll their output.
5. Stop only processes/sessions created for this task.
6. Verify files, processes, Git diff and browser state before reporting.

## Safe completion

Report exact changes, commands and checks. Distinguish verified, partially verified and unverified items. Never claim an action succeeded if it was not observed.

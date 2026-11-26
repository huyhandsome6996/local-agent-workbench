# Windows Agent Workstation Playbook

One paired Windows PC, reusable by ChatGPT Web, Claude Web and MCP-capable local coding agents.

The design solves two separate problems:

- **Remote Desktop Commander Remote** gives a web-based AI agent a secure terminal/files/process bridge to the paired Windows PC.
- **Chrome DevTools MCP** is installed on that PC. The agent runs its CLI through Remote Desktop Commander to inspect browser DOM/accessibility snapshots, interact with real element UIDs, capture screenshots and inspect Console/Network.

## Start here

1. Read `AGENTS.md`.
2. Read `docs/WEB-AGENT-COMPATIBILITY.md`.
3. Read `skills/windows-workstation/SKILL.md` and `skills/repository-intake/SKILL.md`.
4. Confirm Remote Desktop Commander is available and the paired PC is Online.
5. When the task involves a website, use Chrome DevTools CLI through the paired PC's terminal. Do not rely on CMD alone.
6. For a new GitHub project, use `prompts/REPO-HANDOFF.md`.

## Architecture

```text
ChatGPT Web / Claude Web / another remote-MCP host
                 |
                 v
https://mcp.desktopcommander.app/mcp
                 |
                 v
Remote Desktop Commander agent running on Windows
                 |
                 +--> PowerShell / CMD / files / Git
                 |
                 +--> chrome-devtools CLI
                          |
                          v
                 Chrome DevTools MCP
                          |
                          v
                   Chrome browser DOM,
                 accessibility tree, screenshots,
                   Console and Network
```

## Important: connector access is a one-time host setup

A repository cannot grant an AI host permission to control the computer. The host must support remote MCP and the Remote Desktop Commander connector must be connected to the same account that owns the paired device.

- **ChatGPT Web:** Remote Desktop Commander is already installed in the account used for this workstation. Keep it connected and available in the conversation.
- **Claude Web:** add a custom connector once in Customize → Connectors → Add → Custom → Web using `https://mcp.desktopcommander.app/mcp`; authorize the same Remote Desktop Commander account.
- **Other web agents:** connect the remote MCP endpoint if the host supports Streamable HTTP/OAuth.
- **Codex/Antigravity/Claude Desktop/Claude Code:** use the supplied MCP examples or the one-time local configuration.

If the host cannot load remote MCP and has no authorized computer-use tool, it cannot reach the PC. The agent must say so instead of pretending.

## Windows device

The PC was paired by running:

```powershell
npx @wonderwhy-er/desktop-commander@latest remote
```

Keep that terminal window running. Closing it disconnects the PC from Remote Desktop Commander.

## Browser controls

Chrome DevTools MCP `1.14.0` is installed globally. Run on the paired PC through Remote Desktop Commander's terminal:

```powershell
$cli = Join-Path $env:APPDATA 'npm\chrome-devtools.cmd'
& $cli status
& $cli list_pages --output-format=json
& $cli take_snapshot <pageId>
& $cli take_screenshot <pageId> --filePath "$env:USERPROFILE\AgentWorkstation\workspace\page.png"
```

Use fresh accessibility/DOM snapshots and UIDs before clicking/filling. Refresh snapshots after navigation or state changes. Use screenshots, Console, Network and CSS inspection to verify. Chrome remote debugging must be enabled and its permission prompt manually approved by the user; the agent must not automate consent.

## Local installation and tests

Normal, non-Administrator PowerShell from this repository root:

```powershell
.\scripts\Install-AgentWorkstation.ps1
.\scripts\Test-Workstation.ps1
```

Skills are installed globally for Codex and Antigravity. MCP configuration is merged with backups; unrelated servers are preserved. Restart/reload each client after configuration changes.

## Repository workflow

When a user supplies a GitHub URL, the agent must read the instructions, inspect the architecture, dependency manifests, CI, tests and Git state before editing. Reuse clones in `%USERPROFILE%\AgentWorkstation\workspace`. Default to the existing branch. Do not create branches, commits, pushes, PRs, merges or deployments unless the user requests them.

## GitHub publication

GitHub CLI is stored portably under `%USERPROFILE%\AgentWorkstation\tools\gh\gh.exe`. Authenticate using the interactive browser/device login flow, then run `scripts/Publish-GitHub.ps1`. The repository is private by default; the script checks staged file paths, avoids likely secrets, and verifies the pushed remote.

## Security

Never commit PATs, passwords, cookies, browser profiles, local configs, screenshots of private pages or logs containing sensitive material. Chrome DevTools can see content in the connected profile; access only the exact pages authorized by the user. See `docs/SECURITY.md` and `docs/WEB-AGENT-COMPATIBILITY.md`.

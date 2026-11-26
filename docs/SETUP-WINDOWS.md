# Windows setup and operating instructions

This playbook is designed for a normal, non-elevated Windows PowerShell session. Re-check paths and versions on another computer.

## 1. Requirements

- Windows 10/11.
- Windows PowerShell 5.1 or PowerShell 7.
- Node.js and npm.
- Git for Windows.
- Google Chrome stable.
- Desktop Commander connected to the target machine.
- Codex CLI and/or Antigravity with MCP and global skills support.

## 2. Install once

Open normal PowerShell (not Administrator) in the repository root:

    .\scripts\Install-AgentWorkstation.ps1
    .\scripts\Test-Workstation.ps1

The installer:

- Creates %USERPROFILE%\AgentWorkstation\workspace if missing.
- Installs/updates workstation skills for Codex at %USERPROFILE%\.agents\skills.
- Installs/updates the same skills for Antigravity at %USERPROFILE%\.gemini\config\skills.
- Merges Desktop Commander and Chrome DevTools MCP entries into Codex and Antigravity configuration only when missing.
- Makes timestamped backups before modifying an existing MCP configuration or replacing a skill.
- Does not change PATH, Registry, Windows services, firewall or Chrome's own debugging consent.

Existing MCP servers and unrelated JSON/TOML keys are preserved.

## 3. MCP configuration locations

Antigravity:
- MCP: %USERPROFILE%\.gemini\config\mcp_config.json
- Skills: %USERPROFILE%\.gemini\config\skills\

Codex:
- MCP: %USERPROFILE%\.codex\config.toml
- Skills: %USERPROFILE%\.agents\skills\

Restart or reload MCP servers in each client after installation. Verify with the client's MCP view or codex mcp list.

## 4. Chrome DevTools connection and consent

The configured server uses Chrome's autoConnect flow. Chrome remote debugging must already be enabled by the user and Chrome's permission prompt must be approved manually.

Chrome DevTools MCP can inspect and modify pages and data in the connected profile. The agent must never automate the consent prompt, inspect unrelated tabs or expose remote debugging ports to the LAN or internet.

The MCP server configuration disables usage statistics and CrUX URL sharing, redacts network headers, disables file URL navigation and restricts its filesystem tools to the dedicated workspace. These are useful safeguards but do not replace OS-level isolation.

## 5. GitHub CLI for creating/publishing the playbook repo

The official GitHub CLI can be stored portably under:

    %USERPROFILE%\AgentWorkstation\tools\gh\gh.exe

Authenticate interactively with the browser/device flow (do not paste a PAT into chat, terminal history or files):

    & "$env:USERPROFILE\AgentWorkstation\tools\gh\gh.exe" auth login --hostname github.com --git-protocol https --web

Then publish from the repository root:

    .\scripts\Publish-GitHub.ps1

The script creates a private GitHub repository by default, pushes main and verifies the result. It stages only the playbook repository and checks for likely secret file names before publishing. It refuses to overwrite an unrelated origin and never force-pushes.

## 6. Reusable workflow for any new GitHub project

1. Provide the agent the repository URL and task.
2. Ask it to read AGENTS.md, skills/repository-intake/SKILL.md and relevant workstation/browser skills.
3. Ask it to inspect the actual repository state before making changes.
4. Use Desktop Commander for Windows terminal, files, processes and Git.
5. Use Chrome DevTools MCP for browser DOM, accessibility tree, screenshots, Network and Console.
6. Default to the current branch. Do not create a branch, commit, push, merge or deploy unless explicitly requested.

Reusable prompt: prompts/REPO-HANDOFF.md.

## 7. Updating and troubleshooting

- Review the upstream Chrome DevTools MCP changelog before upgrades.
- Update the server and copied skills from the same upstream release.
- If Chrome DevTools waits for a browser or lists no pages, check Chrome's remote-debugging setting and the manual permission prompt.
- Do not use a public bind address or expose a debugging port.
- Stop only a CLI daemon created by the current task, not the user's Chrome process.

## 8. Local layout

- %USERPROFILE%\AgentWorkstation\repo-seed — source repository.
- %USERPROFILE%\AgentWorkstation\workspace — local project clones and task files.
- %USERPROFILE%\AgentWorkstation\tools — portable helper tools.

No PAT, OAuth token, browser profile, environment file, log or workspace content belongs in the published repository.

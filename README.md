# Windows Agent Workstation Playbook

Reusable Windows workstation setup and agent instructions for local development. Desktop Commander operates PowerShell/CMD, files and processes; Chrome DevTools MCP handles browser DOM inspection and automation.

## Capabilities

- Local PowerShell/CMD, filesystem and process work through Desktop Commander MCP.
- Browser inspection and automation through Chrome DevTools MCP.
- Reusable skills for workstation operation, Chrome debugging, troubleshooting and intake of unfamiliar GitHub repositories.
- Safe defaults: inspect first, back up before edits, use a dedicated workspace, preserve existing Git changes, verify results and report blockers honestly.

## Quick start for an agent

1. Read AGENTS.md.
2. Read skills/windows-workstation/SKILL.md and skills/repository-intake/SKILL.md.
3. For browser tasks, read skills/chrome-devtools/SKILL.md and skills/chrome-devtools-cli/SKILL.md.
4. Confirm Desktop Commander is online and Chrome DevTools MCP is connected before using either.
5. For a new project, use prompts/REPO-HANDOFF.md and replace its two placeholders.
6. Work in the user's AgentWorkstation/workspace folder; reuse existing clones.

## Windows installation

Open normal PowerShell (not Administrator) in the repository root:

    .\scripts\Install-AgentWorkstation.ps1
    .\scripts\Test-Workstation.ps1

The installer backs up existing Codex and Antigravity MCP configuration files before merging missing server entries. It installs five skills to the global skill directories and skips identical files. It does not change Windows PATH, Registry, services, firewall or Chrome's debugging consent.

## Agent clients

Antigravity:
- Global MCP config: %USERPROFILE%\.gemini\config\mcp_config.json
- Global skills: %USERPROFILE%\.gemini\config\skills\

Codex:
- MCP config: %USERPROFILE%\.codex\config.toml
- Global skills: %USERPROFILE%\.agents\skills\

Restart/reload the corresponding client MCP servers after configuration changes.

## Browser access model

The Chrome DevTools MCP configuration uses Chrome's autoConnect flow. Chrome remote debugging must already be enabled by the user, and the user must approve Chrome's own permission prompt. The agent must never automate these consent controls. Chrome access exposes the connected profile's pages and data; only touch the tab/page required by the task.

## GitHub repository intake

When a user supplies a repository URL, read AGENTS.md and skills/repository-intake/SKILL.md first. Inspect repo instructions, architecture, dependencies, tests, CI, branch and worktree before changes. Default to the current branch. Do not create branches, commit, push, merge or deploy unless explicitly requested.

Reusable prompt: prompts/REPO-HANDOFF.md.

## Publish this playbook

A portable, checksum-verified GitHub CLI can live at %USERPROFILE%\AgentWorkstation\tools\gh\gh.exe. After the account holder authenticates with the GitHub CLI web/device flow, run:

    .\scripts\Publish-GitHub.ps1

The script creates a private repository by default, checks staged paths for likely secret files, pushes main and verifies the repository URL. It will not force-push or replace an unrelated origin.

## Upstream project

Chrome DevTools MCP: https://github.com/ChromeDevTools/chrome-devtools-mcp

This workstation currently uses chrome-devtools-mcp 1.14.0. Review the upstream changelog and refresh the included upstream skills whenever changing the package version. See THIRD_PARTY_NOTICES.md and LICENSE-CHROME-DEVTOOLS-MCP.txt.

## Secrets and private data

Never commit tokens, passwords, cookies, browser profiles, private configuration, workspace files, screenshots of private pages or logs containing sensitive material. Use a connected GitHub integration or an OS-managed GitHub CLI authentication flow. Never paste PATs into prompts, commands or repository files.

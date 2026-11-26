---
name: windows-workstation
description: Use for safe multi-step Windows workstation tasks through Desktop Commander, PowerShell/CMD, local files, processes, Git repositories and installed tools.
---

# Windows Workstation Skill

## Tool selection

- Use Desktop Commander for local Windows commands, file operations, directory inspection, process inspection and multi-step scripts.
- Use Chrome DevTools MCP for browser automation and DOM inspection.
- Use GitHub integration for GitHub content/repositories where available; do not use a PAT pasted in chat.
- Keep local work in `%USERPROFILE%\AgentWorkstation\workspace`.

## Preflight

1. Confirm the exact device is Online.
2. Check the target path exists and inspect its contents.
3. Inspect running processes before starting/stopping services.
4. Check versions with `node --version`, `npm --version`, `git --version` or the tool relevant to the task.
5. Read project instructions and package scripts.
6. For Git repos run `git status --short --branch` before editing.

## PowerShell best practices

- Use `$ErrorActionPreference = 'Stop'` for scripts that should fail fast.
- Use literal absolute paths and quote them.
- Avoid wildcard deletion and recursive deletes unless explicitly required.
- Make timestamped backups before replacing existing files.
- Use temporary files then atomic move for important config updates.
- Preserve unrelated JSON keys and formatting where practical.
- Never run as Administrator by default.
- Never modify Windows security settings, services, registry or firewall without specific user authorization.

## Multi-task workflow

1. Break the task into independent workstreams.
2. Run independent read-only inspection in parallel.
3. Do not edit the same file concurrently.
4. Keep operations that depend on previous outputs sequential.
5. Record PIDs for long-running tasks and poll their output instead of launching duplicate commands.
6. Stop only the process/session created for this task, not unrelated processes.
7. Verify each output file, process state or Git diff before reporting completion.

## Browser workflow

Follow `../chrome-devtools-cli/SKILL.md` and `../chrome-devtools/SKILL.md`. Browser IDs are ephemeral; re-list pages and re-snapshot after navigation or state changes.

## Safe completion

Summarize the exact changes, commands, checks and open blockers. Distinguish success from partial completion. Never claim a command achieved the desired result without an independent verification.

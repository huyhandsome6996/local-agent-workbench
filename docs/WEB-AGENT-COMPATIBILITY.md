# Use this workstation from ChatGPT Web, Claude Web and other agents

This playbook is designed around one paired Windows computer that can be reached from multiple AI products. The bridge is **Remote Desktop Commander Remote**. Chrome automation runs locally on the paired PC through the installed **Chrome DevTools MCP CLI**.

## The architecture

```text
ChatGPT Web / Claude Web / other remote-MCP agent
                    |
                    | OAuth + Streamable HTTP MCP
                    v
      https://mcp.desktopcommander.app/mcp
                    |
                    | secure relay to paired device
                    v
       Windows PC — Remote Desktop Commander
                    |
                    | PowerShell/CMD runs local command
                    v
          chrome-devtools CLI (local install)
                    |
                    | Chrome DevTools MCP daemon
                    v
       Chrome window/profile on the Windows PC
```

**Important distinction:** the AI service does not gain computer access just because this repository is supplied. The AI host must already have the Remote Desktop Commander connector connected and authorized. The paired Windows device agent must remain running in its terminal. The repository tells the agent which tools to call and how to use them; it cannot grant permissions or install a connector inside an unrelated hosted chat by itself.

## One-time device pairing

The Windows computer was paired by running:

```powershell
npx @wonderwhy-er/desktop-commander@latest remote
```

Keep that terminal window open during work. Closing it disconnects the PC. Check device status in the Remote Desktop Commander dashboard. Do not create a second pairing unless the existing device is actually Offline.

## Connect each AI host once

Use the same Remote Desktop Commander account that owns the paired device.

### ChatGPT Web

Remote Desktop Commander is already installed in the ChatGPT account used for this workstation.

- Open Settings → Apps (or Apps & Connectors) and confirm **Remote Desktop Commander** is connected.
- In a chat, make the Remote Desktop Commander app available to the conversation (use the app picker or mention it by name).
- Ask the agent to list paired devices and confirm the intended Windows PC is Online before running commands.

For a different ChatGPT account, connect the same Remote Desktop Commander app and authenticate the account that can see this paired device. If adding a custom MCP app instead, use the remote MCP endpoint and the ChatGPT Developer mode/connector flow supported by that account.

### Claude Web (claude.ai)

One-time setup:

1. Open Customize → Connectors.
2. Choose Add, then Custom → Web.
3. Name it Remote Desktop Commander.
4. Set the URL to `https://mcp.desktopcommander.app/mcp`.
5. Complete the OAuth sign-in using the same Remote Desktop Commander account that owns the paired Windows PC.
6. In a Claude chat, make sure the connector is enabled and ask it to list the paired devices.

Claude Web uses a **remote connector**. Do not tell Claude Web to edit a local stdio MCP config on Anthropic's cloud host. The cloud connector calls the hosted relay, which reaches the already-paired Windows PC.

### Other web-based agents

The AI product must support **remote MCP connectors using Streamable HTTP and OAuth**. Add:

```text
https://mcp.desktopcommander.app/mcp
```

Authenticate the same Remote Desktop Commander account. If the web agent has no remote MCP connector capability, it cannot call this workstation bridge; use a supported connector-enabled host instead. A repository link alone cannot overcome that host limitation.

### Local coding agents

Codex, Antigravity, Claude Desktop/Code and other MCP-capable desktop agents can connect using either:

- Remote Desktop Commander Remote at the endpoint above (best when the paired device is the target), or
- Desktop Commander local stdio on the same computer.

This repository includes Codex/Antigravity examples and a `.mcp.json` remote MCP entry for Claude Code. OAuth is completed by the client, not by putting credentials in this repository.

## Browser control: Chrome DevTools MCP on the paired PC

Chrome DevTools MCP is installed locally as `chrome-devtools-mcp@1.14.0`, with its CLI at:

```powershell
& "$env:APPDATA\npm\chrome-devtools.cmd"
```

When the AI is connected through Remote Desktop Commander, it should use the terminal tool to run these commands **on the paired Windows PC**, not on the AI provider's cloud machine.

### First browser preflight

```powershell
$cli = Join-Path $env:APPDATA 'npm\chrome-devtools.cmd'
& $cli status
& $cli list_pages --output-format=json
```

If the daemon is not running, start it with the workstation script:

```powershell
& "$env:USERPROFILE\AgentWorkstation\repo-seed\scripts\Start-ChromeDevTools.ps1"
```

The current configuration uses Chrome's `--autoConnect` flow. Chrome 144+ must have remote debugging enabled for that browser instance, and the user must personally review and approve Chrome's permission prompt. **The agent must not silently enable debugging or click the consent prompt.**

If no page is visible, do not claim browser access is working. Ask the user to enable/approve the Chrome remote-debugging connection, then retry `list_pages`.

### DOM, screenshots, Console and Network workflow

1. `chrome-devtools list_pages --output-format=json`
2. Choose the exact requested tab and page ID.
3. `chrome-devtools take_snapshot <pageId>` to inspect the accessibility/DOM-oriented tree and obtain element UIDs.
4. Interact with the identified UID using `click`, `fill`, `press_key` or `type_text`.
5. Take a fresh snapshot after every navigation or major state change.
6. Use `chrome-devtools take_screenshot <pageId> --filePath "<workspace>\after.png"` when a visual check is needed. Read that saved image back through Desktop Commander if the terminal output does not render the image inline.
7. Use `list_console_messages`, `list_network_requests`, `get_network_request` and `get_css_styles` for debugging when needed.

Examples:

```powershell
& $cli take_snapshot 1
& $cli click 1 "1_4" --includeSnapshot true
& $cli take_screenshot 1 --filePath "$env:USERPROFILE\AgentWorkstation\workspace\page.png"
& $cli list_console_messages 1 --types error
& $cli list_network_requests 1 --pageSize 30
```

Page IDs and UIDs are ephemeral. Always refresh them after navigation or UI changes. Prefer DOM/accessibility UIDs over coordinate-based mouse automation. Use screenshots to verify visual results.

## Working in ChatGPT Web or Claude Web tabs

Chrome DevTools can inspect the pages open in the connected Chrome profile, including a ChatGPT Web or Claude Web tab, when that browser profile has explicitly been connected and its consent granted. This is not automatic merely because the model is ChatGPT or Claude.

- Only inspect or interact with the exact tab the user asked about.
- Do not read unrelated conversations, private messages, credentials, cookies, local storage or other account data.
- Do not send a message, submit a form, click a destructive action, publish content or change account settings without the user's explicit instruction.
- When testing an AI chat page, distinguish the website UI from the Remote Desktop Commander connector tools. The connector is the machine-control channel; the page is merely a browser tab.

## Capability check every time

Before a task, the agent must explicitly verify:

- [ ] Remote Desktop Commander tool is available in this conversation.
- [ ] The paired Windows device appears Online.
- [ ] The terminal can run `$env:COMPUTERNAME` and `$env:USERPROFILE` and returns the intended machine.
- [ ] `chrome-devtools status` works on that device.
- [ ] `chrome-devtools list_pages` returns the requested page (if browser work is needed).

If a check fails, report the missing connector, pairing, or user consent. Never pretend to have CMD, DOM, screenshot or browser access.

## Official upstream references

- Remote Desktop Commander Remote: https://github.com/desktop-commander/remote-desktop-commander
- Chrome DevTools MCP: https://github.com/ChromeDevTools/chrome-devtools-mcp
- ChatGPT MCP docs: https://learn.chatgpt.com/docs/extend/mcp
- Claude connectors: https://support.claude.com/en/articles/11176164-use-connectors-to-extend-claude-s-capabilities

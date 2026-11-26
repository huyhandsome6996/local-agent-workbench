[CmdletBinding()]
param(
    [switch]$SkipMcp
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$SourceSkills = Join-Path $RepoRoot 'skills'
$Timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$HomePath = $env:USERPROFILE
$Workspace = Join-Path $HomePath 'AgentWorkstation\workspace'
$NodeCommand = Get-Command node -ErrorAction Stop
$NodeExe = $NodeCommand.Source
$NpmRoot = (npm root -g).Trim()
$ChromePackage = Join-Path $NpmRoot 'chrome-devtools-mcp'
$ChromePackageJson = Join-Path $ChromePackage 'package.json'
$ChromeServer = Join-Path $ChromePackage 'out\Default\gen\src\bin\chrome-devtools-mcp.js'
$CmdExe = Join-Path $env:SystemRoot 'System32\cmd.exe'

function Get-FolderSignature {
    param([string]$Path)
    $items = Get-ChildItem -LiteralPath $Path -File -Recurse | Sort-Object FullName
    $parts = foreach ($item in $items) {
        $relative = $item.FullName.Substring($Path.Length).TrimStart('\')
        $hash = (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash
        "$relative=$hash"
    }
    return ($parts -join [Environment]::NewLine)
}

function Backup-Path {
    param([string]$Path)
    if (Test-Path -LiteralPath $Path) {
        $backup = "$Path.backup_$Timestamp"
        Copy-Item -LiteralPath $Path -Destination $backup -Recurse
        Write-Host "Backup: $backup"
    }
}

function Add-McpEntry {
    param(
        [object]$Config,
        [string]$Name,
        [object]$Entry
    )
    if (-not $Config.mcpServers.PSObject.Properties[$Name]) {
        $Config.mcpServers | Add-Member -NotePropertyName $Name -NotePropertyValue $Entry
        return $true
    }
    return $false
}

Write-Host '=== Windows Agent Workstation installer ==='
Write-Host "Workspace: $Workspace"

if (-not (Test-Path -LiteralPath $Workspace)) {
    New-Item -ItemType Directory -Path $Workspace -Force | Out-Null
}

# 1. Copy skills to the global folders used by Codex and Antigravity.
$SkillRoots = @(
    (Join-Path $HomePath '.agents\skills'),
    (Join-Path $HomePath '.gemini\config\skills')
)
$SkillNames = @(
    'windows-workstation',
    'repository-intake',
    'chrome-devtools',
    'chrome-devtools-cli',
    'troubleshooting'
)

foreach ($root in $SkillRoots) {
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    foreach ($name in $SkillNames) {
        $source = Join-Path $SourceSkills $name
        $destination = Join-Path $root $name
        if (-not (Test-Path -LiteralPath (Join-Path $source 'SKILL.md'))) {
            Write-Warning "Skill source missing; skipped: $source"
            continue
        }

        if (-not (Test-Path -LiteralPath $destination)) {
            Copy-Item -LiteralPath $source -Destination $destination -Recurse
            Write-Host "Installed skill: $destination"
            continue
        }

        $sourceSignature = Get-FolderSignature -Path $source
        $destinationSignature = Get-FolderSignature -Path $destination
        if ($sourceSignature -ne $destinationSignature) {
            Backup-Path -Path $destination
            Copy-Item -LiteralPath $source -Destination $destination -Recurse -Force
            Write-Host "Updated skill (previous copy backed up): $destination"
        }
        else {
            Write-Host "Skill already current: $destination"
        }
    }
}

if (-not $SkipMcp) {
    # 2. Ensure the pinned Chrome DevTools package is present.
    if (-not (Test-Path -LiteralPath $ChromeServer)) {
        Write-Host 'Installing Chrome DevTools MCP 1.14.0 in the current user npm prefix...'
        npm install --global --no-audit --no-fund 'chrome-devtools-mcp@1.14.0'
        if ($LASTEXITCODE -ne 0) { throw 'Chrome DevTools MCP installation failed.' }
    }
    if (-not (Test-Path -LiteralPath $ChromeServer)) {
        throw "Chrome DevTools MCP entry point was not found: $ChromeServer"
    }

    # 3. Merge Antigravity global MCP config; preserve all existing servers.
    $AntigravityConfigPath = Join-Path $HomePath '.gemini\config\mcp_config.json'
    $AntigravityParent = Split-Path -Parent $AntigravityConfigPath
    New-Item -ItemType Directory -Path $AntigravityParent -Force | Out-Null

    if (Test-Path -LiteralPath $AntigravityConfigPath) {
        $AntigravityConfig = Get-Content -Raw -LiteralPath $AntigravityConfigPath | ConvertFrom-Json
    }
    else {
        $AntigravityConfig = [pscustomobject]@{ mcpServers = [pscustomobject]@{} }
    }
    if (-not $AntigravityConfig.mcpServers) {
        $AntigravityConfig | Add-Member -NotePropertyName mcpServers -NotePropertyValue ([pscustomobject]@{})
    }

    $AntigravityChanged = $false
    $AntigravityChanged = (Add-McpEntry -Config $AntigravityConfig -Name 'desktop-commander' -Entry ([pscustomobject]@{
        command = $CmdExe
        args = @('/d', '/s', '/c', 'npx -y @wonderwhy-er/desktop-commander@latest')
    })) -or $AntigravityChanged

    # Remote paired device bridge for web-based agents and remote MCP clients.
    $AntigravityChanged = (Add-McpEntry -Config $AntigravityConfig -Name 'remote-desktop-commander' -Entry ([pscustomobject]@{
        serverUrl = 'https://mcp.desktopcommander.app/mcp'
        timeoutSeconds = 300
    })) -or $AntigravityChanged

    $ChromeArgs = @(
        $ChromeServer,
        '--autoConnect',
        '--usageStatistics=false',
        '--performanceCrux=false',
        '--redactNetworkHeaders=true',
        '--fileNavigations=false',
        '--backgroundNewPages=true',
        "--filesystemRoot=$Workspace"
    )
    $AntigravityChanged = (Add-McpEntry -Config $AntigravityConfig -Name 'chrome-devtools' -Entry ([pscustomobject]@{
        command = $NodeExe
        args = $ChromeArgs
        env = [pscustomobject]@{
            CHROME_DEVTOOLS_MCP_NO_USAGE_STATISTICS = '1'
            CHROME_DEVTOOLS_MCP_NO_UPDATE_CHECKS = '1'
        }
    })) -or $AntigravityChanged

    if ($AntigravityChanged) {
        Backup-Path -Path $AntigravityConfigPath
        $tempConfig = "$AntigravityConfigPath.tmp"
        $AntigravityConfig | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $tempConfig -Encoding UTF8
        Move-Item -LiteralPath $tempConfig -Destination $AntigravityConfigPath -Force
        Write-Host "Updated Antigravity MCP config: $AntigravityConfigPath"
    }
    else {
        Write-Host 'Antigravity MCP config already contains the required servers; left unchanged.'
    }

    # 4. Merge Codex MCP config. Existing sections and other settings are preserved.
    $CodexConfigPath = Join-Path $HomePath '.codex\config.toml'
    $CodexParent = Split-Path -Parent $CodexConfigPath
    New-Item -ItemType Directory -Path $CodexParent -Force | Out-Null
    if (Test-Path -LiteralPath $CodexConfigPath) {
        $CodexToml = Get-Content -Raw -LiteralPath $CodexConfigPath
    }
    else {
        $CodexToml = ''
    }

    function ConvertTo-TomlString {
        param([string]$Value)
        return (ConvertTo-Json -InputObject $Value -Compress)
    }

    $CodexAdditions = @()
    if ($CodexToml -notmatch '(?m)^\[mcp_servers\.desktop-commander\]') {
        $cmdToml = ConvertTo-TomlString -Value $CmdExe
        $CodexAdditions += @"
[mcp_servers.desktop-commander]
command = $cmdToml
args = ["/d", "/s", "/c", "npx -y @wonderwhy-er/desktop-commander@latest"]
startup_timeout_ms = 30000
"@
    }

    if ($CodexToml -notmatch '(?m)^\[mcp_servers\.remote-desktop-commander\]') {
        $CodexAdditions += @'
[mcp_servers.remote-desktop-commander]
url = "https://mcp.desktopcommander.app/mcp"
startup_timeout_ms = 30000
'@
    }

    if ($CodexToml -notmatch '(?m)^\[mcp_servers\.chrome-devtools\]') {
        $nodeToml = ConvertTo-TomlString -Value $NodeExe
        $serverToml = ConvertTo-TomlString -Value $ChromeServer
        $workspaceArg = ConvertTo-TomlString -Value "--filesystemRoot=$Workspace"
        $CodexAdditions += @"
[mcp_servers.chrome-devtools]
command = $nodeToml
args = [$serverToml, "--autoConnect", "--usageStatistics=false", "--performanceCrux=false", "--redactNetworkHeaders=true", "--fileNavigations=false", "--backgroundNewPages=true", $workspaceArg]
env = { CHROME_DEVTOOLS_MCP_NO_USAGE_STATISTICS = "1", CHROME_DEVTOOLS_MCP_NO_UPDATE_CHECKS = "1" }
startup_timeout_ms = 20000
"@
    }

    if ($CodexAdditions.Count -gt 0) {
        Backup-Path -Path $CodexConfigPath
        Add-Content -LiteralPath $CodexConfigPath -Value ([Environment]::NewLine + ($CodexAdditions -join ([Environment]::NewLine + [Environment]::NewLine))) -Encoding UTF8
        Write-Host "Updated Codex MCP config: $CodexConfigPath"
    }
    else {
        Write-Host 'Codex MCP config already contains the required servers; left unchanged.'
    }
}

Write-Host ''
Write-Host 'Installation step finished. Restart/reload Codex and Antigravity MCP servers.'
Write-Host "Chrome autoConnect still requires the user's Chrome remote-debugging consent."

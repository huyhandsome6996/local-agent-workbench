param(
    [string]$Workspace = "$env:USERPROFILE\AgentWorkstation\workspace"
)

$ErrorActionPreference = 'Stop'
$cli = Join-Path $env:APPDATA 'npm\chrome-devtools.cmd'

if (-not (Test-Path -LiteralPath $cli)) {
    throw "Chrome DevTools CLI was not found at: $cli. Install chrome-devtools-mcp first."
}

if (-not (Test-Path -LiteralPath $Workspace)) {
    New-Item -ItemType Directory -Path $Workspace -Force | Out-Null
}

Write-Host "Connecting to the user's already-running Chrome profile with --autoConnect."
Write-Host "Chrome remote debugging must already be enabled by the user, and the user must approve Chrome's permission prompt."
Write-Host "Browser MCP file access is restricted to: $Workspace"

$env:CHROME_DEVTOOLS_MCP_NO_USAGE_STATISTICS = '1'
$env:CHROME_DEVTOOLS_MCP_NO_UPDATE_CHECKS = '1'

$cliArgs = @(
    'start',
    '--autoConnect',
    '--headless=false',
    '--usageStatistics=false',
    '--performanceCrux=false',
    '--redactNetworkHeaders=true',
    '--fileNavigations=false',
    '--backgroundNewPages=true',
    "--filesystemRoot=$Workspace"
)

& $cli @cliArgs
if ($LASTEXITCODE -ne 0) {
    throw "Chrome DevTools MCP start failed with exit code $LASTEXITCODE."
}

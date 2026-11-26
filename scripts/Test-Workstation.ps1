$ErrorActionPreference = 'Stop'
$npmBin = Join-Path $env:APPDATA 'npm'
$package = Join-Path $npmBin 'node_modules\chrome-devtools-mcp\package.json'
$cli = Join-Path $npmBin 'chrome-devtools.cmd'
$mcpBin = Join-Path $npmBin 'chrome-devtools-mcp.cmd'
$workspace = Join-Path $env:USERPROFILE 'AgentWorkstation\workspace'
$agyConfig = Join-Path $env:USERPROFILE '.gemini\config\mcp_config.json'
$codexConfig = Join-Path $env:USERPROFILE '.codex\config.toml'
$skillNames = @('windows-workstation', 'repository-intake', 'chrome-devtools', 'chrome-devtools-cli', 'troubleshooting')
$skillRoots = @(
    (Join-Path $env:USERPROFILE '.agents\skills'),
    (Join-Path $env:USERPROFILE '.gemini\config\skills')
)

Write-Host '--- Node ---'
node --version
Write-Host '--- npm ---'
npm --version
Write-Host '--- Git ---'
git --version
Write-Host '--- Chrome DevTools package ---'
if (-not (Test-Path -LiteralPath $package)) { throw "Package missing: $package" }
$version = (Get-Content -Raw $package | ConvertFrom-Json).version
Write-Host $version
Write-Host '--- CLI entry points ---'
[pscustomobject]@{ CLI=(Test-Path $cli); MCP=(Test-Path $mcpBin) } | Format-List
if (-not (Test-Path $cli) -or -not (Test-Path $mcpBin)) { throw 'Chrome DevTools CLI entry points are missing.' }

Write-Host '--- Workspace ---'
if (-not (Test-Path $workspace)) { New-Item -ItemType Directory -Path $workspace -Force | Out-Null }
Write-Output $workspace

Write-Host '--- Antigravity MCP ---'
if (-not (Test-Path $agyConfig)) { throw "Antigravity MCP config missing: $agyConfig" }
$agy = Get-Content -Raw -LiteralPath $agyConfig | ConvertFrom-Json
$agyNames = @($agy.mcpServers.PSObject.Properties.Name)
$agyNames
foreach ($name in @('desktop-commander', 'chrome-devtools')) {
    if ($name -notin $agyNames) { throw "Antigravity MCP server missing: $name" }
}

Write-Host '--- Codex MCP TOML ---'
if (-not (Test-Path $codexConfig)) { throw "Codex config missing: $codexConfig" }
python -c "import os,tomllib; p=os.path.expanduser('~/.codex/config.toml'); d=tomllib.load(open(p,'rb')); names=d.get('mcp_servers',{}).keys(); required={'desktop-commander','chrome-devtools'}; missing=required-set(names); print('Codex servers: '+', '.join(names)); raise SystemExit(bool(missing))"
if ($LASTEXITCODE -ne 0) { throw 'Codex MCP config is missing a required server or has invalid TOML.' }

Write-Host '--- Global skills ---'
foreach ($root in $skillRoots) {
    foreach ($name in $skillNames) {
        $skillFile = Join-Path (Join-Path $root $name) 'SKILL.md'
        if (-not (Test-Path -LiteralPath $skillFile)) { throw "Skill missing: $skillFile" }
        Write-Host "OK $skillFile"
    }
}

Write-Host '--- GitHub CLI (optional publish dependency) ---'
$portableGh = Join-Path $env:USERPROFILE 'AgentWorkstation\tools\gh\gh.exe'
if (Test-Path -LiteralPath $portableGh) { & $portableGh --version }
else { Write-Host 'Not installed; local workstation skills remain usable.' }

Write-Host '--- Desktop Commander ---'
Write-Host 'MCP config is present. Restart/reload Codex or Antigravity to verify live connection.'
Write-Host '--- Result ---'
Write-Host 'Static workstation checks passed. Live MCP handshake and browser consent are verified in the agent client.'

param([switch]$ListPages)

$ErrorActionPreference = 'Stop'
$cli = Join-Path $env:APPDATA 'npm\chrome-devtools.cmd'
if (-not (Test-Path -LiteralPath $cli)) { throw "CLI not found: $cli" }

& $cli status
if ($LASTEXITCODE -ne 0) { throw "Status command failed: $LASTEXITCODE" }

if ($ListPages) {
    & $cli list_pages --output-format=json
    if ($LASTEXITCODE -ne 0) { throw "list_pages failed: $LASTEXITCODE" }
}

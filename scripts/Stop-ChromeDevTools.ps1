# Stops the Chrome DevTools MCP CLI daemon. It does not shut down Windows.
$ErrorActionPreference = 'Stop'
$cli = Join-Path $env:APPDATA 'npm\chrome-devtools.cmd'
if (-not (Test-Path -LiteralPath $cli)) { throw "CLI not found: $cli" }

& $cli stop
if ($LASTEXITCODE -ne 0) { throw "Stop command failed: $LASTEXITCODE" }

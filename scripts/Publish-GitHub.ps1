[CmdletBinding()]
param(
    [string]$RepositoryName = 'local-agent-workbench',
    [ValidateSet('private', 'public', 'internal')]
    [string]$Visibility = 'private',
    [string]$Description = 'Reusable Windows workstation playbook for Desktop Commander, Chrome DevTools MCP and safe AI-agent repository workflows.'
)
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
$GhPath = Join-Path $env:USERPROFILE 'AgentWorkstation\tools\gh\gh.exe'
if (-not (Test-Path -LiteralPath $GhPath)) {
    $ghCommand = Get-Command gh -ErrorAction SilentlyContinue
    if ($ghCommand) { $GhPath = $ghCommand.Source }
}
if (-not (Test-Path -LiteralPath $GhPath)) {
    throw "GitHub CLI was not found. See docs/SETUP-WINDOWS.md."
}

& $GhPath auth status
if ($LASTEXITCODE -ne 0) {
    throw "GitHub CLI is not authenticated. Run: gh auth login --hostname github.com --git-protocol https --web"
}

$login = (& $GhPath api user --jq .login).Trim()
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($login)) {
    throw 'Could not determine the authenticated GitHub account.'
}
$fullName = "$login/$RepositoryName"

$existingRepo = $false
$repoNames = @(& $GhPath repo list $login --limit 1000 --json name --jq '.[].name')
if ($LASTEXITCODE -ne 0) { throw 'Could not list repositories for the authenticated GitHub account.' }
$existingRepo = $repoNames -contains $RepositoryName

if (-not (Test-Path -LiteralPath (Join-Path $RepoRoot '.git'))) {
    git -C $RepoRoot init --initial-branch=main
    if ($LASTEXITCODE -ne 0) { throw 'git init failed.' }
}

git -C $RepoRoot config user.name $login
if ($LASTEXITCODE -ne 0) { throw 'Could not set repository-local Git author name.' }
$userId = (& $GhPath api user --jq .id).Trim()
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($userId)) { throw 'Could not resolve GitHub account ID.' }
$noReplyEmail = "$userId+$login@users.noreply.github.com"
git -C $RepoRoot config user.email $noReplyEmail
if ($LASTEXITCODE -ne 0) { throw 'Could not set repository-local Git author email.' }

git -C $RepoRoot add -A
if ($LASTEXITCODE -ne 0) { throw 'git add failed.' }
git -C $RepoRoot status --short
git -C $RepoRoot diff --cached --check
if ($LASTEXITCODE -ne 0) { throw 'Staged diff check failed.' }
$staged = @(git -C $RepoRoot diff --cached --name-only)
if ($staged.Count -gt 0) {
    $sensitive = $staged | Where-Object { $_ -match '(^|/)(\.env|\.env\.|secrets?\.|credentials?\.)|\.pem$|\.key$|\.pfx$|\.p12$|\.log$|\.har$|\.heapsnapshot$' }
    if ($sensitive) {
        throw "Potentially sensitive file staged: $($sensitive -join ', '). Review before publishing."
    }
    git -C $RepoRoot diff --cached --stat
    $hasCommit = git -C $RepoRoot rev-parse --verify HEAD 2>$null
    if ($LASTEXITCODE -eq 0) {
        git -C $RepoRoot commit -m 'Update Windows agent workstation playbook'
    }
    else {
        git -C $RepoRoot commit -m 'Initial Windows agent workstation playbook'
    }
    if ($LASTEXITCODE -ne 0) { throw 'Git commit failed.' }
}
else {
    $hasCommit = git -C $RepoRoot rev-parse --verify HEAD 2>$null
    if ($LASTEXITCODE -ne 0) { throw 'No staged files or existing commit; refusing to publish an empty repository.' }
}

if (-not $existingRepo) {
    $createArgs = @(
        $fullName,
        "--$Visibility",
        "--description=$Description",
        "--source=$RepoRoot",
        "--remote=origin",
        '--push'
    )
    & $GhPath repo create @createArgs
    if ($LASTEXITCODE -ne 0) { throw 'GitHub repository creation or initial push failed.' }
}
else {
    $remote = git -C $RepoRoot remote get-url origin 2>$null
    if ($LASTEXITCODE -eq 0 -and $remote -and $remote -notmatch "github\.com[:/]$([regex]::Escape($fullName))(\.git)?$") {
        throw "Existing origin points to another repository ($remote). Refusing to change it."
    }
    if (-not $remote) {
        git -C $RepoRoot remote add origin "https://github.com/$fullName.git"
        if ($LASTEXITCODE -ne 0) { throw 'Could not add origin remote.' }
    }
    git -C $RepoRoot push -u origin main
    if ($LASTEXITCODE -ne 0) { throw 'Push failed.' }
}

& $GhPath repo view $fullName --json url,isPrivate,defaultBranchRef --jq '{url: .url, private: .isPrivate, branch: .defaultBranchRef.name}'
if ($LASTEXITCODE -ne 0) { throw 'Could not verify the published repository.' }
$ErrorActionPreference = 'Stop'

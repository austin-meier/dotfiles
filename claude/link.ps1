#requires -Version 5.1
<#
.SYNOPSIS
    Link this repo's Claude Code config into ~/.claude and register user-scope MCP servers.

.DESCRIPTION
    Creates symlinks from ~/.claude/<item> to ~/.config/claude/<item> for the authored config
    items only (settings.json, CLAUDE.md, skills/, commands/, agents/, output-styles/). All
    machine state under ~/.claude (history, sessions, caches, credentials) is left untouched.

    Then reads mcp-servers.json and registers each server at user scope via the claude CLI.

    Idempotent: re-running skips links that are already correct. Any real file/dir found at a
    link target is moved aside to <name>.backup-<timestamp> before the link is created.

    NOTE: Creating symlinks on Windows requires either Developer Mode (Settings > System >
    For developers) or an elevated (Administrator) PowerShell. If linking fails with a
    privilege error, enable Developer Mode or re-run this script as Administrator.

    NOTE: keep this file pure ASCII. Windows PowerShell 5.1 reads BOM-less scripts as the
    ANSI codepage, where multi-byte UTF-8 (em dashes, box glyphs) can decode into curly quotes
    that break parsing.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# --- Logging helpers ---------------------------------------------------------
function Info    { param($m) Write-Host "  > $m" -ForegroundColor Blue }
function Success { param($m) Write-Host "  + $m" -ForegroundColor Green }
function Warn    { param($m) Write-Host "  ! $m" -ForegroundColor Yellow }
function Die     { param($m) Write-Host "  x $m" -ForegroundColor Red; exit 1 }

$RepoClaude = $PSScriptRoot
$ClaudeHome = Join-Path $HOME '.claude'
$Stamp      = Get-Date -Format 'yyyyMMdd-HHmmss'

Write-Host "`nClaude config link  " -NoNewline
Write-Host "$RepoClaude -> $ClaudeHome" -ForegroundColor DarkGray

if (-not (Test-Path $ClaudeHome)) {
    Info "Creating $ClaudeHome"
    New-Item -ItemType Directory -Path $ClaudeHome | Out-Null
}

# --- Preflight: confirm we can create symlinks BEFORE moving any real files ---
# On Windows this needs Developer Mode or elevation. Probe with a throwaway link so a
# privilege failure can't strand a backed-up file with no link in its place. Target a FILE
# (not the repo dir): a file symlink validates the same privilege but, unlike a directory
# symlink, can be deleted without Remove-Item trying to recurse into the target.
$probeTarget = Join-Path $RepoClaude 'settings.json'
$probe = Join-Path $ClaudeHome ".link-probe-$Stamp"
try {
    $null = New-Item -ItemType SymbolicLink -Path $probe -Target $probeTarget -ErrorAction Stop
    (Get-Item $probe -Force).Delete()
}
catch {
    try { if (Test-Path $probe) { (Get-Item $probe -Force).Delete() } } catch {}
    Die "Cannot create symlinks here. Enable Developer Mode (Settings > System > For developers) or run this script as Administrator, then re-run.`n  Detail: $($_.Exception.Message)"
}

# --- Symlink table: name in ~/.claude => source in the repo ------------------
$Links = @(
    'settings.json'
    'CLAUDE.md'
    'skills'
    'commands'
    'agents'
    'output-styles'
)

function Link-Item {
    param([string]$Name)

    $source = Join-Path $RepoClaude $Name
    $target = Join-Path $ClaudeHome $Name

    if (-not (Test-Path $source)) { Warn "skip $Name (no source in repo)"; return }

    if (Test-Path $target) {
        $item = Get-Item $target -Force
        if ($item.LinkType -eq 'SymbolicLink') {
            $current = $item.Target
            if ($current -eq $source) { Success "$Name already linked"; return }
            Info "Replacing stale link $Name (was -> $current)"
            # .Delete() removes only the reparse point. Remove-Item on a directory symlink in
            # PS 5.1 tries to recurse into the target and can delete the linked repo's contents.
            (Get-Item $target -Force).Delete()
        }
        else {
            $kind = if ($item.PSIsContainer) { 'dir' } else { 'file' }
            $backup = "$target.backup-$Stamp"
            Warn "$Name exists as a real $kind - moving to $(Split-Path $backup -Leaf)"
            Move-Item $target $backup
        }
    }

    New-Item -ItemType SymbolicLink -Path $target -Target $source -ErrorAction Stop | Out-Null
    Success "linked $Name"
}

Write-Host "`nSymlinks" -ForegroundColor White
foreach ($name in $Links) { Link-Item $name }

# --- MCP servers (user scope) ------------------------------------------------
Write-Host "`nMCP servers (user scope)" -ForegroundColor White
$claude = Get-Command claude -ErrorAction SilentlyContinue
if (-not $claude) {
    Warn "claude CLI not on PATH - skipping MCP registration. Install Claude Code, then re-run."
}
else {
    $manifestPath = Join-Path $RepoClaude 'mcp-servers.json'
    if (-not (Test-Path $manifestPath)) {
        Warn "no mcp-servers.json - skipping MCP registration"
    }
    else {
        $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
        $servers  = $manifest.mcpServers
        foreach ($prop in $servers.PSObject.Properties) {
            if ($prop.Name -eq '//') { continue }
            $serverName = $prop.Name
            $cfg  = $prop.Value
            $type = if ($cfg.type) { $cfg.type } else { 'stdio' }

            # Build the arg list and splat it (& claude @args). Passing a quoted JSON blob as a
            # native arg is mangled by PowerShell 5.1, so use the flag form of `claude mcp add`.
            $addArgs = @('mcp', 'add', '--scope', 'user', '--transport', $type)
            if ($type -eq 'http' -or $type -eq 'sse') {
                if ($cfg.headers) {
                    foreach ($h in $cfg.headers.PSObject.Properties) {
                        $addArgs += @('--header', ('{0}: {1}' -f $h.Name, $h.Value))
                    }
                }
                $addArgs += @($serverName, $cfg.url)
            }
            else {
                # stdio: optional env vars, then name, then `--` and the command/args.
                if ($cfg.env) {
                    foreach ($e in $cfg.env.PSObject.Properties) {
                        $addArgs += @('-e', ('{0}={1}' -f $e.Name, $e.Value))
                    }
                }
                $addArgs += $serverName
                $addArgs += '--'
                $addArgs += $cfg.command
                if ($cfg.args) { $addArgs += $cfg.args }
            }

            Info "registering '$serverName' ($type)"
            # Remove first so the manifest is the source of truth (ignore "not found").
            try { & claude mcp remove $serverName --scope user 2>$null | Out-Null } catch {}
            & claude @addArgs | Out-Null
            if ($LASTEXITCODE -eq 0) { Success "registered '$serverName'" }
            else { Warn "could not register '$serverName' (exit $LASTEXITCODE)" }
        }
    }
}

Write-Host "`nDone." -ForegroundColor Green
Write-Host "  Authenticate any HTTP/OAuth MCP servers inside Claude with: " -NoNewline
Write-Host "/mcp" -ForegroundColor DarkGray

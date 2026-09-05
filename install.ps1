<#
.SYNOPSIS
   Windows host bootstrap. WezTerm, its font, and a WSL2 check. Nothing else.

.DESCRIPTION
   These dotfiles are unix. On Windows the real install happens inside WSL2 and
   the host only needs the terminal and its font, so this script deliberately has
   no Node dependency: you should not be installing Node on the Windows side at
   all. A Windows node.exe leaking into WSL through PATH interop is the cause of
   most "Claude Code is flaky in WSL" weirdness. See WINDOWS-MIGRATION.md.

   The two winget ids below are asserted against install/lib/programs.ts by the
   test suite, so they can't drift from the registry.

.PARAMETER Native
   Install the degraded native-Windows stack instead of using WSL2, for a machine
   where WSL2 isn't an option. You lose zsh, starship, and Emacs. This path runs
   the full TypeScript installer, so it does need Node >= 22.18 on Windows.

.PARAMETER DryRun
   Print what would happen without doing it.

.EXAMPLE
   pwsh install.ps1
   pwsh install.ps1 -DryRun
   pwsh install.ps1 -Native
#>
[CmdletBinding()]
param(
   [switch]$Native,
   [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

function Write-Info { param($Message) Write-Host "   $Message" -ForegroundColor Blue }
function Write-Ok   { param($Message) Write-Host "   $Message" -ForegroundColor Green }
function Write-Warn { param($Message) Write-Host "   $Message" -ForegroundColor Yellow }

# ─── Escape hatch: full native-Windows install ────────────────────────────────
if ($Native) {
   if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
      Write-Error '-Native runs the TypeScript installer and needs Node >= 22.18 on Windows.'
      exit 1
   }
   $extra = @('--native')
   if ($DryRun) { $extra += '--dry-run' }
   node "$root\install\install.ts" @extra
   exit $LASTEXITCODE
}

# ─── WSL2 ─────────────────────────────────────────────────────────────────────
# Advisory, not a gate. A false negative here should not block two harmless
# winget installs, so a parsing miss degrades to a warning.
$hasWsl2 = $false
if (Get-Command wsl.exe -ErrorAction SilentlyContinue) {
   $env:WSL_UTF8 = '1'
   $listing = ((& wsl.exe --list --verbose 2>$null) -join "`n") -replace "`0", ''
   # Columns: optional * marker, NAME, STATE, VERSION.
   $hasWsl2 = $listing -match '(?m)^\s*\*?\s*\S+\s+\S+\s+2\s*$'
}

if ($hasWsl2) {
   Write-Ok 'WSL2 distro detected'
} else {
   Write-Warn 'No WSL2 distro detected. Installing the host side anyway.'
   Write-Info '    wsl --install -d Ubuntu           # then reboot if prompted'
   Write-Info '    wsl --set-version <distro> 2      # if you are on WSL1'
}

# ─── Host packages ────────────────────────────────────────────────────────────
$packages = @(
   @{ Name = 'WezTerm';                  Id = 'wez.wezterm' },
   @{ Name = 'JetBrainsMono Nerd Font';  Id = 'DEVCOM.JetBrainsMonoNerdFont' }
)

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
   Write-Error 'winget not found. Install App Installer from the Microsoft Store, then re-run.'
   exit 1
}

foreach ($package in $packages) {
   $command = "winget install --id $($package.Id) --exact --silent " +
              '--accept-source-agreements --accept-package-agreements'

   if ($DryRun) {
      Write-Info "would run: $command"
      continue
   }

   Write-Info "installing $($package.Name)"
   & winget install --id $package.Id --exact --silent `
      --accept-source-agreements --accept-package-agreements

   # winget returns 0x8A15002B when the package is already installed.
   if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq -1978335189) {
      Write-Ok "$($package.Name) ready"
   } else {
      Write-Warn "$($package.Name) exited $LASTEXITCODE"
   }
}

# ─── Next ─────────────────────────────────────────────────────────────────────
Write-Host ''
Write-Ok 'Host side done. The dotfiles themselves install inside WSL2:'
Write-Info '    wsl -- bash -c "sudo apt update && sudo apt install -y curl git"'
Write-Info '    wsl -- bash -c "git clone git@github.com:austin-meier/dotfiles.git ~/.config"'
Write-Info '    wsl -- bash ~/.config/install.sh'
Write-Host ''
Write-Info "Moving an existing setup across? Read $root\WINDOWS-MIGRATION.md first."
Write-Info 'Install Node inside WSL, never on Windows. WINDOWS-MIGRATION.md step 6 explains why.'

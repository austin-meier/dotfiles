<#
.SYNOPSIS
   Windows host bootstrap. WezTerm, its font, a required WSL2 gate, and pointing
   WezTerm at the WSL dotfiles. Nothing else.

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
$wsl2Distros = @()
if (Get-Command wsl.exe -ErrorAction SilentlyContinue) {
   $env:WSL_UTF8 = '1'
   $listing = ((& wsl.exe --list --verbose 2>$null) -join "`n") -replace "`0", ''
   foreach ($line in ($listing -split "`n")) {
      if ($line -match '^\s*(\*?)\s*(\S+)\s+\S+\s+2\s*$') {
         $wsl2Distros += [pscustomobject]@{ Default = $matches[1] -eq '*'; Name = $matches[2] }
      }
   }
}

if ($wsl2Distros.Count -eq 0) {
   Write-Warn 'No WSL2 distro found. These dotfiles install inside WSL2; the host only carries WezTerm and its font.'
   Write-Info '    wsl --install -d Ubuntu           # then reboot if prompted'
   Write-Info '    wsl --set-version <distro> 2      # if you are on WSL1'
   Write-Info 'Then re-run. If WSL2 genuinely is not an option here, use -Native for the degraded native stack.'
   exit 1
}

$distroName = ($wsl2Distros | Where-Object { $_.Default } | Select-Object -First 1).Name
if (-not $distroName) { $distroName = $wsl2Distros[0].Name }
Write-Ok "WSL2 distro detected: $distroName"

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

$wslHome = (& wsl.exe -d $distroName -- sh -c 'printf %s "$HOME"' 2>$null)
$wslHome = ($wslHome -replace "`0", '').Trim()
$configUnc = "\\wsl.localhost\$distroName$($wslHome.Replace('/', '\'))\.config\wezterm\wezterm.lua"

if ($wslHome -and (Test-Path -LiteralPath $configUnc)) {
   if ($DryRun) {
      Write-Info "would set WEZTERM_CONFIG_FILE -> $configUnc"
   } elseif ([Environment]::GetEnvironmentVariable('WEZTERM_CONFIG_FILE', 'User') -ne $configUnc) {
      [Environment]::SetEnvironmentVariable('WEZTERM_CONFIG_FILE', $configUnc, 'User')
      Write-Ok "WEZTERM_CONFIG_FILE -> $configUnc"
   } else {
      Write-Ok 'WEZTERM_CONFIG_FILE already current'
   }
} else {
   Write-Info 'WSL dotfiles clone not found yet; WezTerm config source left unset.'
   Write-Info 'Re-run after cloning the dotfiles in WSL, or set WEZTERM_CONFIG_FILE by hand (WINDOWS-MIGRATION.md step 7).'
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

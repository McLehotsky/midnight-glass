<#
.SYNOPSIS
  Installs Midnight Glass and its vibrancy setup into VS Code on this machine.
  Applies to the Default profile and every other existing profile.

.EXAMPLE
  .\setup\install.ps1           # install into all profiles
  .\setup\install.ps1 -DryRun   # only print the resulting settings, write nothing
#>
param(
    [switch]$DryRun
)
$ErrorActionPreference = 'Stop'

$root    = Split-Path $PSScriptRoot -Parent            # the midnight-glass folder
$userDir = Join-Path $env:APPDATA 'Code\User'
$extDir  = Join-Path $env:USERPROFILE '.vscode\extensions'

if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
    throw "The 'code' command is not on PATH. Install VS Code (with 'Add to PATH') and open a new terminal."
}

# --- 1. profiles -------------------------------------------------------------
# Default plus every profile listed in storage.json. A profile that shares
# settings or extensions with Default (useDefaultFlags) is skipped for that part.
$profiles = @([pscustomobject]@{
    Name = 'Default'; Args = @(); Settings = (Join-Path $userDir 'settings.json')
    OwnSettings = $true; OwnExtensions = $true
})
$storagePath = Join-Path $userDir 'globalStorage\storage.json'
if (Test-Path $storagePath) {
    $storage = Get-Content $storagePath -Raw | ConvertFrom-Json
    foreach ($p in @($storage.userDataProfiles)) {
        if (-not $p) { continue }
        $flags = $p.useDefaultFlags
        $profiles += [pscustomobject]@{
            Name = $p.name; Args = @('--profile', $p.name)
            Settings = (Join-Path $userDir "profiles\$($p.location)\settings.json")
            OwnSettings = -not ($flags -and $flags.settings)
            OwnExtensions = -not ($flags -and $flags.extensions)
        }
    }
}
Write-Host "== Profiles: $(($profiles.Name) -join ', ')" -ForegroundColor Cyan

# --- 2. extensions -----------------------------------------------------------
$extensions = Get-Content (Join-Path $PSScriptRoot 'extensions.txt') |
    ForEach-Object { $_.Trim() } | Where-Object { $_ -and -not $_.StartsWith('#') }
$vsix = Get-ChildItem $root -Filter 'midnight-glass-*.vsix' | Sort-Object Name | Select-Object -Last 1
if (-not $vsix) { throw "No midnight-glass-*.vsix found in $root" }

if (-not $DryRun) {
    foreach ($prof in $profiles | Where-Object OwnExtensions) {
        Write-Host "== Extensions -> $($prof.Name)" -ForegroundColor Cyan
        $a = $prof.Args
        foreach ($e in $extensions) { code @a --install-extension $e --force }
        code @a --install-extension $vsix.FullName --force
    }
}

# --- 3. settings template with resolved paths -------------------------------
$anim = Get-ChildItem $extDir -Directory -Filter 'brandonkirbyson.vscode-animations-*' -ErrorAction SilentlyContinue |
        Sort-Object Name | Select-Object -Last 1
$animPath = if ($anim) { $anim.FullName } else { Join-Path $extDir 'brandonkirbyson.vscode-animations-VERSION' }

$tpl = Get-Content (Join-Path $PSScriptRoot 'settings.template.json') -Raw
$tpl = $tpl.Replace('{{STYLES_DIR}}', ($root -replace '\\', '/'))
$tpl = $tpl.Replace('{{ANIMATIONS_DIR}}', ($animPath -replace '\\', '/'))

# --- 4. merge into each profile: only template keys change, the rest stays ---
foreach ($prof in $profiles | Where-Object OwnSettings) {
    $settingsPath = $prof.Settings
    $new = $tpl | ConvertFrom-Json

    try {
        $current = if (Test-Path $settingsPath) { Get-Content $settingsPath -Raw | ConvertFrom-Json } else { $null }
    } catch {
        throw "Could not parse $settingsPath (comments or a trailing comma?). Run the script with PowerShell 7 (pwsh) or fix the file. $_"
    }
    if (-not $current) { $current = [pscustomobject]@{} }

    foreach ($p in $new.PSObject.Properties) {
        if ($p.Name -eq 'workbench.colorCustomizations' -and $current.PSObject.Properties[$p.Name]) {
            # keep other themes in colorCustomizations, replace only the [Midnight Glass] block
            $cc = $current.($p.Name)
            foreach ($t in $p.Value.PSObject.Properties) { $cc | Add-Member -NotePropertyName $t.Name -NotePropertyValue $t.Value -Force }
        } else {
            $current | Add-Member -NotePropertyName $p.Name -NotePropertyValue $p.Value -Force
        }
    }
    $json = $current | ConvertTo-Json -Depth 20

    if ($DryRun) {
        Write-Host "== DryRun [$($prof.Name)]: $settingsPath would become:" -ForegroundColor Yellow
        $json
        continue
    }

    if (Test-Path $settingsPath) {
        $bak = "$settingsPath.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
        Copy-Item $settingsPath $bak
        Write-Host "Backup of previous settings: $bak"
    }
    New-Item -ItemType Directory -Force (Split-Path $settingsPath) | Out-Null
    [IO.File]::WriteAllText($settingsPath, $json, [Text.UTF8Encoding]::new($false))
    Write-Host "== Settings written [$($prof.Name)]: $settingsPath" -ForegroundColor Green
}

if ($DryRun) { return }

Write-Host @"

Remaining steps in VS Code (Ctrl+Shift+P):
  1. Reload Vibrancy            -> restart VS Code
  2. Custom UI Style: Reload    -> restart VS Code
  3. 'Installation appears to be corrupt' -> Don't show again
Repeat step 1 (and 2) after every VS Code update.
"@ -ForegroundColor Cyan

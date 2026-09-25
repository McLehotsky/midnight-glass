<#
.SYNOPSIS
  Nainštaluje Midnight Glass + vibrancy setup do VS Code na tomto PC.

.EXAMPLE
  .\setup\install.ps1                  # Default profil
  .\setup\install.ps1 -VSProfile WebDev  # konkrétny profil (musí už existovať)
  .\setup\install.ps1 -DryRun          # len ukáže výsledné settings, nič nezapíše
#>
param(
    [string]$VSProfile = '',
    [switch]$DryRun
)
$ErrorActionPreference = 'Stop'

$root      = Split-Path $PSScriptRoot -Parent            # priečinok midnight-glass
$userDir   = Join-Path $env:APPDATA 'Code\User'
$extDir    = Join-Path $env:USERPROFILE '.vscode\extensions'
$profArgs  = if ($VSProfile) { @('--profile', $VSProfile) } else { @() }

if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
    throw "Príkaz 'code' nie je v PATH. Nainštaluj VS Code (s voľbou 'Add to PATH') a otvor nový terminál."
}

# --- 1. extensions ---------------------------------------------------------
if (-not $DryRun) {
    Write-Host '== Extensions' -ForegroundColor Cyan
    Get-Content (Join-Path $PSScriptRoot 'extensions.txt') |
        Where-Object { $_ -and -not $_.StartsWith('#') } |
        ForEach-Object { code @profArgs --install-extension $_.Trim() --force }

    $vsix = Get-ChildItem $root -Filter 'midnight-glass-*.vsix' | Sort-Object Name | Select-Object -Last 1
    if (-not $vsix) { throw "Chýba midnight-glass-*.vsix v $root" }
    code @profArgs --install-extension $vsix.FullName --force
}

# --- 2. cieľový settings.json ----------------------------------------------
if ($VSProfile) {
    $storage  = Get-Content (Join-Path $userDir 'globalStorage\storage.json') -Raw | ConvertFrom-Json
    $location = ($storage.userDataProfiles | Where-Object name -eq $VSProfile).location
    if (-not $location) { throw "Profil '$VSProfile' neexistuje. Vytvor ho vo VS Code (Profiles > New Profile) a spusti skript znova." }
    $settingsPath = Join-Path $userDir "profiles\$location\settings.json"
} else {
    $settingsPath = Join-Path $userDir 'settings.json'
}

# --- 3. šablóna s doplnenými cestami ---------------------------------------
$anim = Get-ChildItem $extDir -Directory -Filter 'brandonkirbyson.vscode-animations-*' -ErrorAction SilentlyContinue |
        Sort-Object Name | Select-Object -Last 1
$animPath = if ($anim) { $anim.FullName } else { Join-Path $extDir 'brandonkirbyson.vscode-animations-VERSION' }

$tpl = Get-Content (Join-Path $PSScriptRoot 'settings.template.json') -Raw
$tpl = $tpl.Replace('{{STYLES_DIR}}', ($root -replace '\\', '/'))
$tpl = $tpl.Replace('{{ANIMATIONS_DIR}}', ($animPath -replace '\\', '/'))
$new = $tpl | ConvertFrom-Json

# --- 4. merge: prepíšu sa len kľúče zo šablóny, ostatné nastavenia zostanú --
try {
    $current = if (Test-Path $settingsPath) { Get-Content $settingsPath -Raw | ConvertFrom-Json } else { $null }
} catch {
    throw "Nepodarilo sa prečítať $settingsPath (komentáre alebo čiarka navyše?). Spusti skript cez PowerShell 7 (pwsh) alebo súbor oprav. $_"
}
if (-not $current) { $current = [pscustomobject]@{} }

foreach ($p in $new.PSObject.Properties) {
    if ($p.Name -eq 'workbench.colorCustomizations' -and $current.PSObject.Properties[$p.Name]) {
        # zachová iné témy v colorCustomizations, prepíše len blok [Midnight Glass]
        $cc = $current.($p.Name)
        foreach ($t in $p.Value.PSObject.Properties) { $cc | Add-Member -NotePropertyName $t.Name -NotePropertyValue $t.Value -Force }
    } else {
        $current | Add-Member -NotePropertyName $p.Name -NotePropertyValue $p.Value -Force
    }
}
$json = $current | ConvertTo-Json -Depth 20

if ($DryRun) {
    Write-Host "== DryRun: $settingsPath by vyzeral takto:" -ForegroundColor Yellow
    $json
    return
}

if (Test-Path $settingsPath) {
    $bak = "$settingsPath.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
    Copy-Item $settingsPath $bak
    Write-Host "Záloha pôvodných settings: $bak"
}
New-Item -ItemType Directory -Force (Split-Path $settingsPath) | Out-Null
[IO.File]::WriteAllText($settingsPath, $json, [Text.UTF8Encoding]::new($false))
Write-Host "== Settings zapísané do $settingsPath" -ForegroundColor Green

Write-Host @"

Zostáva spraviť vo VS Code (Ctrl+Shift+P):
  1. Reload Vibrancy            -> reštart VS Code
  2. Custom UI Style: Reload    -> reštart VS Code
  3. 'Installation appears to be corrupt' -> Don't show again
Po každom update VS Code zopakuj krok 1 (a 2).
"@ -ForegroundColor Cyan

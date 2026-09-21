<#
.SYNOPSIS
  Compiles this project's Papyrus scripts.

.DESCRIPTION
  Compiles papyrus/ into build/papyrus/ against the reconstructed base sources and
  Rapport's API.
  Those sources live outside the game folder deliberately: the compiler takes import
  paths, so Vortex never sees them and nothing gets deployed that should not be.

  NEVER compile into Data/Scripts. That directory is Vortex-deployed.

  ASCII only. Windows PowerShell 5.1 reads a BOM-less UTF-8 script as ANSI, and one
  non-ASCII character in a string is enough to turn this into a parse error that
  still exits 0.

  See docs/papyrus-toolchain.md, especially the part about default arguments: the
  decompiled base sources have none, so every argument must be passed explicitly.
#>
[CmdletBinding()]
param(
    [string] $Base     = 'D:\F4CustomMods\PapyrusBase\Source\Base',
    [string] $Compiler = 'D:\GOGGames\Fallout 4 GOTY\Papyrus Compiler\PapyrusCompiler.exe',
    # Chemistry calls Rapport:Core, so Rapport's sources must be on the IMPORT path.
    # Imported, not compiled: nothing of Rapport's is built or shipped from here. If
    # this path is wrong the failure is "variable Rapport:Core is undefined", which
    # is the clearest error the compiler gives for it.
    [string] $Rapport  = 'C:\Users\DuduPhudu\Documents\Projects\fo4-rapport\papyrus',
    [switch] $Quiet
)

$ErrorActionPreference = 'Stop'
$root    = Split-Path -Parent $PSScriptRoot
$sources = Join-Path $root 'papyrus'
$out     = Join-Path $root 'build\papyrus'
# Import-only declarations (MCM). A separate folder from papyrus/ so nothing in it
# is ever compiled or shipped.
$stubs   = Join-Path $root 'papyrus-stubs'

if (-not (Test-Path $Compiler)) {
    throw "No Papyrus compiler at $Compiler."
}
if (-not (Test-Path (Join-Path $Base 'Institute_Papyrus_Flags.flg'))) {
    throw "No Institute_Papyrus_Flags.flg in $Base. Run tools/papyrus_setup.py first."
}
if (-not (Test-Path (Join-Path $Rapport 'Rapport\Core.psc'))) {
    throw "No Rapport\Core.psc under $Rapport. Chemistry compiles against Rapport's API; point -Rapport at the sibling checkout."
}
if (-not (Test-Path $sources)) {
    Write-Host "No papyrus/ directory yet - nothing to compile."
    exit 0
}

New-Item -ItemType Directory -Force -Path $out | Out-Null

$scripts = Get-ChildItem -Recurse -Filter *.psc $sources
if ($scripts.Count -eq 0) {
    Write-Host "No .psc files under $sources - nothing to compile."
    exit 0
}

Write-Host "Compiling $($scripts.Count) script(s) against $Base"

# Batch mode, not file by file. A namespaced script (Rapport:Bridge) compiled by
# path fails with "filename does not match script name": the namespace has to come
# from the import paths, which -all does and a single file path cannot.
$output = & $Compiler $sources -all -f="Institute_Papyrus_Flags.flg" -i="$Base;$sources;$Rapport;$stubs" -o="$out" 2>&1

# Print everything the compiler said. An earlier version filtered this to lines
# matching "error", which hid the only message that explained a failure.
$output | ForEach-Object { Write-Host "  $_" }

$built = Get-ChildItem -Recurse -Filter *.pex $out -ErrorAction SilentlyContinue
Write-Host ""
Write-Host "$($built.Count) .pex in $out"
if ($output -match 'compilation failed' -or $output -match '0 succeeded') { exit 1 }

<#
.SYNOPSIS
  Puts Chemistry into its Vortex staging folder.

.DESCRIPTION
  Chemistry is two files: the generated esp and one compiled script. There is no
  native code, no config and no assets -- all of that is Rapport's.

  A NEW file needs Vortex's Deploy button. Vortex hardlinks staging into the game,
  so an existing file updates in place and a new one does not exist in Data until
  Vortex is told to link it. The first run of this script is therefore always
  followed by pressing Deploy, and by enabling Chemistry.esp in the load order.

  ASCII only. Windows PowerShell 5.1 reads a BOM-less UTF-8 script as ANSI, and one
  non-ASCII character in a string is enough to make this a parse error that still
  exits 0.
#>
[CmdletBinding()]
param(
    [string] $Staging = 'D:\Vortex\fallout4\mods\Chemistry-dev'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

# The game must be closed for the same reason as Rapport: a loaded pex is not
# replaced, and a half-updated pair of files is worse than an old one.
if (Get-Process -Name 'Fallout4' -ErrorAction SilentlyContinue) {
    throw "Fallout 4 is running. Close it first."
}

New-Item -ItemType Directory -Force -Path $Staging | Out-Null

$esp = Join-Path $root 'data\Chemistry.esp'
if (-not (Test-Path $esp)) {
    throw "No data\Chemistry.esp - run: python tools\make_esp.py data\Chemistry.esp"
}
Copy-Item $esp $Staging -Force

$pex = Join-Path $root 'build\papyrus\Chemistry'
if (-not (Test-Path $pex)) {
    throw "No build\papyrus\Chemistry - run scripts\build-papyrus.ps1"
}
$scripts = Join-Path $Staging 'Scripts\Chemistry'
New-Item -ItemType Directory -Force -Path $scripts | Out-Null
Copy-Item (Join-Path $pex '*.pex') $scripts -Force

foreach ($f in @((Join-Path $Staging 'Chemistry.esp'),
                 (Join-Path $Staging 'Scripts\Chemistry\Autonomy.pex'))) {
    if (Test-Path $f) {
        $i = Get-Item $f
        Write-Host ("  {0}  {1} bytes  {2}" -f $i.FullName, $i.Length, $i.LastWriteTime.ToString('HH:mm:ss'))
    }
}

Write-Host ""
Write-Host "Staged. If this is the first time, in Vortex:"
Write-Host "  1. Deploy (these are new files, so the hardlinks do not exist yet)"
Write-Host "  2. enable Chemistry.esp in the load order, after Rapport.esp"
Write-Host "Then launch through F4SE. Chemistry logs into Rapport.log, prefixed 'chemistry:'."

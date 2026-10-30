#requires -Version 5.1
# Build dist\ : self-test, compile with ps2exe, copy ps1 + run.cmd.
Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$src = Join-Path $PSScriptRoot 'jhcis-installer.ps1'

# 1. BOM required (Thai text breaks in Windows PowerShell 5.1 without it)
$head = [IO.File]::ReadAllBytes($src)[0..2]
if (-not ($head[0] -eq 0xEF -and $head[1] -eq 0xBB -and $head[2] -eq 0xBF)) {
    throw 'jhcis-installer.ps1 has no UTF-8 BOM (Thai text will break in Windows PowerShell 5.1)'
}

# 2. Self test
& powershell -NoProfile -ExecutionPolicy Bypass -File $src -SelfTest
if ($LASTEXITCODE -ne 0) { throw "SelfTest failed (exit $LASTEXITCODE)" }

# 3. ps2exe
if (-not (Get-Module -ListAvailable ps2exe)) {
    Install-Module ps2exe -Scope CurrentUser -Force
}
Import-Module ps2exe

# 4. Version
$m = Select-String -Path $src -Pattern '^\$Script:Version = ''([^'']+)''' | Select-Object -First 1
if (-not $m) { throw 'Cannot read $Script:Version from jhcis-installer.ps1' }
$version = $m.Matches[0].Groups[1].Value

# 5. Compile
New-Item -ItemType Directory -Force dist | Out-Null
Remove-Item .\dist\jhcis-installer.exe -ErrorAction SilentlyContinue  # never keep a stale exe
Invoke-ps2exe -inputFile $src -outputFile .\dist\jhcis-installer.exe -noConsole -requireAdmin -x64 `
    -title 'JHCIS Client Installer' -product 'PowerPCU JHCIS Installer' -version "$version.0"

# 6. Copy fallbacks
Copy-Item $src .\dist\ -Force
Copy-Item .\run.cmd .\dist\ -Force

# 7. Sanity
$exe = Get-Item .\dist\jhcis-installer.exe
if ($exe.Length -ge 1MB) { throw "exe is $($exe.Length) bytes (>= 1 MB), unexpected" }
Get-ChildItem .\dist -File | ForEach-Object { Write-Host ('{0,12:N0}  {1}' -f $_.Length, $_.Name) }

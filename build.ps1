# Builds dist\HighPen.exe and dist\HighPen-Setup.exe from src\ (no SDK needed; uses .NET Framework's csc).
$ErrorActionPreference = 'Stop'
$fw   = 'C:\Windows\Microsoft.NET\Framework64\v4.0.30319'
$wpf  = "$fw\WPF"
$src  = Join-Path $PSScriptRoot 'src'
$dist = Join-Path $PSScriptRoot 'dist'
$ico  = Join-Path $src 'HighPen.ico'
$out  = Join-Path $dist 'HighPen.exe'
$setup = Join-Path $dist 'HighPen-Setup.exe'

New-Item -ItemType Directory -Force $dist | Out-Null
if (-not (Test-Path $ico)) { & (Join-Path $src 'make-icon.ps1') }
Get-Process HighPen -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $out } | Stop-Process -Force

# 1) the app
& "$fw\csc.exe" /nologo /target:winexe /optimize+ "/win32icon:$ico" "/out:$out" `
    "/r:$wpf\PresentationFramework.dll" "/r:$wpf\PresentationCore.dll" `
    "/r:$wpf\WindowsBase.dll" "/r:$fw\System.Xaml.dll" "/r:$fw\System.Windows.Forms.dll" "/r:$fw\System.Drawing.dll" `
    (Join-Path $src 'HighPen.cs')
if ($LASTEXITCODE -ne 0) { exit 1 }
Write-Host "Built $out"

# 2) the installer (HighPen.exe embedded as a resource)
& "$fw\csc.exe" /nologo /target:winexe /optimize+ "/win32icon:$ico" "/out:$setup" "/resource:$out,HighPen.exe" `
    "/r:$fw\System.Windows.Forms.dll" (Join-Path $src 'Setup.cs')
if ($LASTEXITCODE -ne 0) { exit 1 }
Write-Host "Built $setup"

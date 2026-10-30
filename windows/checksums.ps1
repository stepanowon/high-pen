# Writes dist\SHA256SUMS.txt for the files to upload to a GitHub release (run after build.ps1 and packaging\build-msix.ps1).
# Same format as sha256sum, so it can also be checked with: sha256sum -c SHA256SUMS.txt
$ErrorActionPreference = 'Stop'
$dist = Join-Path $PSScriptRoot 'dist'
$files = 'HighPen-Setup.exe', 'HighPen.exe', 'HighPen.msix' | Where-Object { Test-Path (Join-Path $dist $_) }
if (-not $files) { throw "nothing to hash in $dist; build first" }
$lines = foreach ($f in $files) { (Get-FileHash (Join-Path $dist $f) -Algorithm SHA256).Hash.ToLower() + '  ' + $f }
[IO.File]::WriteAllLines((Join-Path $dist 'SHA256SUMS.txt'), [string[]]$lines)
$lines
Write-Host "Wrote $(Join-Path $dist 'SHA256SUMS.txt')"

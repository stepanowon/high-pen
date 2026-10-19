# Generates HighPen.ico (PNG-compressed, 16/24/32/48/64/128/256) from vector drawing code.
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'Stop'

function New-IconBitmap([int]$n) {
    $bmp = New-Object Drawing.Bitmap $n, $n, ([Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.Clear([Drawing.Color]::Transparent)
    $u = $n / 256.0

    # rounded dark background
    $path = New-Object Drawing.Drawing2D.GraphicsPath
    $r = 52 * $u; $d = 2 * $r; $s = $n - 1
    $path.AddArc(0, 0, $d, $d, 180, 90); $path.AddArc($s - $d, 0, $d, $d, 270, 90)
    $path.AddArc($s - $d, $s - $d, $d, $d, 0, 90); $path.AddArc(0, $s - $d, $d, $d, 90, 90)
    $path.CloseFigure()
    $g.FillPath((New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(255, 0x2B, 0x2E, 0x33))), $path)

    # yellow mouse spot
    $g.FillEllipse((New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(200, 0xFF, 0xD6, 0x0A))), 34*$u, 100*$u, 120*$u, 120*$u)

    # pen (rotated rounded body + tip), drawn upright then rotated 45deg around the centre
    $g.TranslateTransform(150*$u, 112*$u)
    $g.RotateTransform(40)
    $body = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(255, 0xFF, 0x3B, 0x30))
    $g.FillRectangle($body, -17*$u, -100*$u, 34*$u, 110*$u)
    $g.FillRectangle((New-Object Drawing.SolidBrush ([Drawing.Color]::White)), -17*$u, -100*$u, 34*$u, 20*$u)
    $tip = [Drawing.PointF[]]@([Drawing.PointF]::new(-17*$u, 10*$u), [Drawing.PointF]::new(17*$u, 10*$u), [Drawing.PointF]::new(0, 55*$u))
    $g.FillPolygon((New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(255, 0xF2, 0xD3, 0xA8))), $tip)
    $nib = [Drawing.PointF[]]@([Drawing.PointF]::new(-6*$u, 41*$u), [Drawing.PointF]::new(6*$u, 41*$u), [Drawing.PointF]::new(0, 55*$u))
    $g.FillPolygon((New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(255, 0x33, 0x33, 0x33))), $nib)
    $g.Dispose()
    return $bmp
}

$sizes = 16, 24, 32, 48, 64, 128, 256
$pngs = foreach ($n in $sizes) {
    $b = New-IconBitmap $n
    $ms = New-Object IO.MemoryStream
    $b.Save($ms, [Drawing.Imaging.ImageFormat]::Png)
    , $ms.ToArray()
}

$out = Join-Path $PSScriptRoot 'HighPen.ico'
$fs = [IO.File]::Create($out)
$w = New-Object IO.BinaryWriter $fs
$w.Write([uint16]0); $w.Write([uint16]1); $w.Write([uint16]$sizes.Count)
$offset = 6 + 16 * $sizes.Count
for ($i = 0; $i -lt $sizes.Count; $i++) {
    $n = $sizes[$i]; $dim = if ($n -ge 256) { 0 } else { $n }
    $w.Write([byte]$dim); $w.Write([byte]$dim); $w.Write([byte]0); $w.Write([byte]0)
    $w.Write([uint16]1); $w.Write([uint16]32)
    $w.Write([uint32]$pngs[$i].Length); $w.Write([uint32]$offset)
    $offset += $pngs[$i].Length
}
foreach ($p in $pngs) { $w.Write($p) }
$w.Close()

# preview for a quick look
(New-IconBitmap 256).Save((Join-Path $PSScriptRoot 'HighPen-icon-preview.png'), [Drawing.Imaging.ImageFormat]::Png)
Write-Host "Wrote $out"

# MSIX logos (packaging\Assets): the icon on a transparent canvas, scale-100/200 and taskbar target sizes
function Save-Logo([string]$name, [int]$w, [int]$h, [int]$icon) {
    $bmp = New-Object Drawing.Bitmap $w, $h, ([Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [Drawing.Graphics]::FromImage($bmp)
    $g.Clear([Drawing.Color]::Transparent)
    $i = New-IconBitmap $icon
    $g.DrawImage($i, [int](($w - $icon) / 2), [int](($h - $icon) / 2), $icon, $icon)
    $g.Dispose(); $i.Dispose()
    $bmp.Save((Join-Path $assets "$name.png"), [Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}
$assets = Join-Path $PSScriptRoot '..\packaging\Assets'
New-Item -ItemType Directory -Force $assets | Out-Null
foreach ($s in 1, 2) {
    Save-Logo "Square44x44Logo.scale-$($s * 100)" (44 * $s) (44 * $s) (36 * $s)
    Save-Logo "Square150x150Logo.scale-$($s * 100)" (150 * $s) (150 * $s) (100 * $s)
    Save-Logo "Wide310x150Logo.scale-$($s * 100)" (310 * $s) (150 * $s) (100 * $s)
    Save-Logo "StoreLogo.scale-$($s * 100)" (50 * $s) (50 * $s) (50 * $s)
}
foreach ($n in 16, 24, 32, 48, 256) {
    Save-Logo "Square44x44Logo.targetsize-$n" $n $n $n
    Save-Logo "Square44x44Logo.targetsize-${n}_altform-unplated" $n $n $n
}
Write-Host "Wrote MSIX logos to $assets"

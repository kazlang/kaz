# scripts/generate_icons.ps1
# Generates PNGs of various sizes and a Windows .ico file from the new Kaz logo

param(
    [string]$SourcePath = "C:\Users\Armando\.gemini\antigravity\brain\eda8bfd7-0a7b-49a5-910f-5e6d31b7a899\.user_uploaded\media_1790604743602.jpg"
)

Add-Type -AssemblyName System.Drawing

if (-not (Test-Path $SourcePath)) {
    Write-Error "Source image not found at $SourcePath"
    exit 1
}

$kazRoot = (Get-Item $PSScriptRoot).Parent.FullName
$kazPublicRoot = "C:\ProjetosAM\kaz-public"

Write-Host "Loading source image from: $SourcePath" -ForegroundColor Cyan
$sourceBmp = [System.Drawing.Bitmap]::FromFile($SourcePath)
Write-Host "Source dimensions: $($sourceBmp.Width) x $($sourceBmp.Height)" -ForegroundColor Green

function Resize-Image($src, [int]$targetWidth, [int]$targetHeight) {
    $destRect = New-Object System.Drawing.Rectangle(0, 0, $targetWidth, $targetHeight)
    $destImage = New-Object System.Drawing.Bitmap($targetWidth, $targetHeight, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    
    $graphics = [System.Drawing.Graphics]::FromImage($destImage)
    $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    
    $graphics.DrawImage($src, $destRect, 0, 0, $src.Width, $src.Height, [System.Drawing.GraphicsUnit]::Pixel)
    $graphics.Dispose()
    
    return $destImage
}

function Image-To-Png-Bytes($img) {
    $ms = New-Object System.IO.MemoryStream
    $img.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $bytes = $ms.ToArray()
    $ms.Dispose()
    return $bytes
}

# 1. Generate sizes: 16, 32, 48, 64, 128, 256, 512, 1024
$sizes = @(16, 32, 48, 64, 128, 256, 512, 1024)
$resizedMap = @{}
$pngBytesMap = @{}

foreach ($s in $sizes) {
    $img = Resize-Image $sourceBmp $s $s
    $resizedMap[$s] = $img
    $pngBytesMap[$s] = Image-To-Png-Bytes $img
}

# 2. Save VS Code / Lumina extension icon (512x512 PNG)
$vscodeIconPath1 = Join-Path $kazRoot "editors\vscode\icon.png"
[System.IO.File]::WriteAllBytes($vscodeIconPath1, $pngBytesMap[512])
Write-Host "Updated: $vscodeIconPath1 (512x512)" -ForegroundColor Green

$vscodeIconPath2 = Join-Path $kazPublicRoot "editors\vscode\icon.png"
if (Test-Path (Split-Path $vscodeIconPath2 -Parent)) {
    [System.IO.File]::WriteAllBytes($vscodeIconPath2, $pngBytesMap[512])
    Write-Host "Updated: $vscodeIconPath2 (512x512)" -ForegroundColor Green
}

# 3. Save assets PNGs in kaz and kaz-public
$assetsDirs = @(
    (Join-Path $kazRoot "assets"),
    (Join-Path $kazPublicRoot "assets")
)

foreach ($assetsDir in $assetsDirs) {
    if (-not (Test-Path $assetsDir)) { continue }
    
    # Save standard size PNGs
    [System.IO.File]::WriteAllBytes((Join-Path $assetsDir "kaz-icon-16.png"), $pngBytesMap[16])
    [System.IO.File]::WriteAllBytes((Join-Path $assetsDir "kaz-icon-32.png"), $pngBytesMap[32])
    [System.IO.File]::WriteAllBytes((Join-Path $assetsDir "kaz-icon-48.png"), $pngBytesMap[48])
    [System.IO.File]::WriteAllBytes((Join-Path $assetsDir "kaz-icon-64.png"), $pngBytesMap[64])
    [System.IO.File]::WriteAllBytes((Join-Path $assetsDir "kaz-icon-128.png"), $pngBytesMap[128])
    [System.IO.File]::WriteAllBytes((Join-Path $assetsDir "kaz-icon-256.png"), $pngBytesMap[256])
    [System.IO.File]::WriteAllBytes((Join-Path $assetsDir "kaz-icon-512.png"), $pngBytesMap[512])
    [System.IO.File]::WriteAllBytes((Join-Path $assetsDir "kaz-icon-1024.png"), $pngBytesMap[1024])
    
    # Also update legacy names so existing scripts and assets reflect the new logo
    [System.IO.File]::WriteAllBytes((Join-Path $assetsDir "logo-32x32.png"), $pngBytesMap[32])
    [System.IO.File]::WriteAllBytes((Join-Path $assetsDir "flux-icon-16.png"), $pngBytesMap[16])
    [System.IO.File]::WriteAllBytes((Join-Path $assetsDir "flux-icon-32.png"), $pngBytesMap[32])
    [System.IO.File]::WriteAllBytes((Join-Path $assetsDir "flux-icon-48.png"), $pngBytesMap[48])
    [System.IO.File]::WriteAllBytes((Join-Path $assetsDir "flux-icon-64.png"), $pngBytesMap[64])
    [System.IO.File]::WriteAllBytes((Join-Path $assetsDir "flux-icon-128.png"), $pngBytesMap[128])
    [System.IO.File]::WriteAllBytes((Join-Path $assetsDir "flux-icon-256.png"), $pngBytesMap[256])
    [System.IO.File]::WriteAllBytes((Join-Path $assetsDir "flux-icon-512.png"), $pngBytesMap[512])
    [System.IO.File]::WriteAllBytes((Join-Path $assetsDir "flux-nobg-1024.png"), $pngBytesMap[1024])
    [System.IO.File]::WriteAllBytes((Join-Path $assetsDir "flux-nobg-512.png"), $pngBytesMap[512])
    [System.IO.File]::WriteAllBytes((Join-Path $assetsDir "flux-nobg-256.png"), $pngBytesMap[256])
    Write-Host "Updated PNG assets in: $assetsDir" -ForegroundColor Green
}

# 4. Generate standard Windows .ico for NSIS & Windows Shell compatibility
$iconHandle = $resizedMap[32].GetHicon()
$systemIcon = [System.Drawing.Icon]::FromHandle($iconHandle)

foreach ($assetsDir in $assetsDirs) {
    if (-not (Test-Path $assetsDir)) { continue }
    $kazIco = Join-Path $assetsDir "kaz.ico"
    $fluxIco = Join-Path $assetsDir "flux.ico"
    
    $fs1 = [System.IO.File]::Create($kazIco)
    $systemIcon.Save($fs1)
    $fs1.Close()
    
    $fs2 = [System.IO.File]::Create($fluxIco)
    $systemIcon.Save($fs2)
    $fs2.Close()
    
    Write-Host "Generated standard ICO in: $kazIco and $fluxIco" -ForegroundColor Green
}
$systemIcon.Dispose()

# Cleanup
foreach ($img in $resizedMap.Values) {
    $img.Dispose()
}
$sourceBmp.Dispose()

Write-Host "=== All icons generated and synchronized successfully! ===" -ForegroundColor Cyan

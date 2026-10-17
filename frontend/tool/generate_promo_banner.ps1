# Generates docs/portfolio/jimatmy_promo_banner.png (1200x628)
# Run: powershell -ExecutionPolicy Bypass -File tool/generate_promo_banner.ps1
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

# ---- Brand palette -------------------------------------------------------
$deep   = [System.Drawing.ColorTranslator]::FromHtml('#0D5B3D')
$green  = [System.Drawing.ColorTranslator]::FromHtml('#167D55')
$mint   = [System.Drawing.ColorTranslator]::FromHtml('#E5F5EA')
$cream  = [System.Drawing.ColorTranslator]::FromHtml('#FFFCF4')
$yellow = [System.Drawing.ColorTranslator]::FromHtml('#F4C95D')
$ink    = [System.Drawing.ColorTranslator]::FromHtml('#16342A')
$softInk= [System.Drawing.ColorTranslator]::FromHtml('#6B7F74')
$white  = [System.Drawing.Color]::White

$W = 1200
$H = 628
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$outPath = Join-Path $repo 'docs\portfolio\jimatmy_promo_banner.png'
$outDir = Split-Path -Parent $outPath
if (-not (Test-Path -LiteralPath $outDir)) {
  New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

$bmp = New-Object System.Drawing.Bitmap($W, $H, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$g.Clear($deep)

# ---- Vertical green gradient ---------------------------------------------
$full = New-Object System.Drawing.Rectangle(0, 0, $W, $H)
$grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush($full, $deep, $green, 90.0)
$g.FillRectangle($grad, $full)
$grad.Dispose()

function New-RoundedPath([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
  $p = New-Object System.Drawing.Drawing2D.GraphicsPath
  $d = $r * 2
  $p.AddArc($x, $y, $d, $d, 180, 90)
  $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
  $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
  $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
  $p.CloseFigure()
  return $p
}

function Draw-TextCentered(
  [string]$text, [float]$cx, [float]$cy,
  [float]$px, [System.Drawing.FontStyle]$style,
  [System.Drawing.Color]$color, [string]$family = 'Segoe UI') {
  $font = New-Object System.Drawing.Font($family, $px, $style, [System.Drawing.GraphicsUnit]::Pixel)
  $brush = New-Object System.Drawing.SolidBrush($color)
  $size = $g.MeasureString($text, $font)
  $g.DrawString($text, $font, $brush, $cx - $size.Width / 2, $cy - $size.Height / 2)
  $brush.Dispose()
  $font.Dispose()
}

function Draw-TextLeft(
  [string]$text, [float]$x, [float]$y,
  [float]$px, [System.Drawing.FontStyle]$style,
  [System.Drawing.Color]$color, [string]$family = 'Segoe UI') {
  $font = New-Object System.Drawing.Font($family, $px, $style, [System.Drawing.GraphicsUnit]::Pixel)
  $brush = New-Object System.Drawing.SolidBrush($color)
  $g.DrawString($text, $font, $brush, $x, $y)
  $brush.Dispose()
  $font.Dispose()
}

# ---- Soft decorative circles ---------------------------------------------
$softWhite = [System.Drawing.Color]::FromArgb(22, $white)
$softMint  = [System.Drawing.Color]::FromArgb(28, $mint)
$sb1 = New-Object System.Drawing.SolidBrush($softWhite)
$sb2 = New-Object System.Drawing.SolidBrush($softMint)
$g.FillEllipse($sb2, 900, -90, 430, 430)
$g.FillEllipse($sb1, -70, 470, 300, 300)
$g.FillEllipse($sb2, 60, -110, 240, 240)
$sb1.Dispose()
$sb2.Dispose()

# ---- "Official data" pill ------------------------------------------------
$pillBrush = New-Object System.Drawing.SolidBrush($cream)
$pillTextBrush = New-Object System.Drawing.SolidBrush($deep)
$g.FillPath($pillBrush, (New-RoundedPath 80 108 300 54 27))
Draw-TextCentered 'Compare prices daily' 230 135 22 ([System.Drawing.FontStyle]::Bold) $deep

# ---- Headline (left) ------------------------------------------------------
Draw-TextLeft 'JimatMY' 80 185 112 ([System.Drawing.FontStyle]::Bold) $white
Draw-TextLeft 'Save every day. Shop smarter.' 84 335 42 ([System.Drawing.FontStyle]::Bold) $yellow
Draw-TextLeft 'Real Malaysian grocery prices from PriceCatcher open data.' 84 410 22 ([System.Drawing.FontStyle]::Regular) $mint

# ---- CTA pill (left) ------------------------------------------------------
$ctaBrush = New-Object System.Drawing.SolidBrush($yellow)
$ctaText = New-Object System.Drawing.SolidBrush($deep)
$g.FillPath($ctaBrush, (New-RoundedPath 80 500 280 62 31))
Draw-TextCentered 'Start comparing  >' 220 531 24 ([System.Drawing.FontStyle]::Bold) $deep

# ---- Feature card (right) -------------------------------------------------
$cardBrush = New-Object System.Drawing.SolidBrush($white)
$g.FillPath($cardBrush, (New-RoundedPath 800 150 320 360 32))
$cardBrush.Dispose()

$mintBrush = New-Object System.Drawing.SolidBrush($mint)
$g.FillEllipse($mintBrush, 900, 196, 120, 120)   # circle around RM arrow
$mintBrush.Dispose()

# Down arrow inside the circle
$arrow = [System.Drawing.Color]::FromArgb(230, $green)
$arrowBrush = New-Object System.Drawing.SolidBrush($arrow)
$p1 = New-Object System.Drawing.PointF(960, 322)
$p2 = New-Object System.Drawing.PointF(920, 270)
$p3 = New-Object System.Drawing.PointF(1000, 270)
$pts = @($p1, $p2, $p3)
$g.FillPolygon($arrowBrush, $pts)
$arrowBrush.Dispose()

# Card text
Draw-TextCentered 'RM' 960 224 30 ([System.Drawing.FontStyle]::Bold) $green
Draw-TextCentered 'Lowest prices at a glance' 960 356 23 ([System.Drawing.FontStyle]::Bold) $ink
Draw-TextCentered 'Nearest premises, one compare' 960 392 16 ([System.Drawing.FontStyle]::Regular) $softInk

# Thin yellow accent bar under card
$barBrush = New-Object System.Drawing.SolidBrush($yellow)
$g.FillRectangle($barBrush, 800, 524, 320, 8)
$barBrush.Dispose()

# ---- Finalize ---------------------------------------------------------------
$pillBrush.Dispose()
$pillTextBrush.Dispose()
$ctaBrush.Dispose()
$ctaText.Dispose()
$g.Dispose()
$bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Host "Saved $outPath"

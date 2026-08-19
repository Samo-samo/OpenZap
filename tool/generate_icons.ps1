param(
    [string]$OutputDir = "D:\codis\openzap\assets\icon"
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$Navy     = [System.Drawing.Color]::FromArgb(12, 25, 60)
$White    = [System.Drawing.Color]::FromArgb(255, 255, 255)
$WhiteLow = [System.Drawing.Color]::FromArgb(232, 237, 247)
$BgTop    = [System.Drawing.Color]::FromArgb(12, 25, 60)
$BgBottom = [System.Drawing.Color]::FromArgb(34, 48, 94)
$Trans    = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)

function New-Graphics {
    param([System.Drawing.Bitmap]$Bitmap)
    $g = [System.Drawing.Graphics]::FromImage($Bitmap)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    return $g
}

function New-RoundedRectPath {
    param([float]$X, [float]$Y, [float]$W, [float]$H, [float]$Radius)
    $p = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $d = $Radius * 2.0
    $p.AddArc($X, $Y, $d, $d, 180, 90)
    $p.AddArc($X + $W - $d, $Y, $d, $d, 270, 90)
    $p.AddArc($X + $W - $d, $Y + $H - $d, $d, $d, 0, 90)
    $p.AddArc($X, $Y + $H - $d, $d, $d, 90, 90)
    $p.CloseFigure()
    return $p
}

function Draw-Glyph {
    param(
        [System.Drawing.Graphics]$Graphics,
        [string]$PowerMode,
        [switch]$GradientBody
    )

    $tvRect = [System.Drawing.RectangleF]::new(282.0, 362.0, 460.0, 300.0)
    $tvPath = New-RoundedRectPath -X 282.0 -Y 362.0 -W 460.0 -H 300.0 -Radius 44.0

    if ($GradientBody) {
        $bodyBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
            $tvRect,
            $White,
            $WhiteLow,
            [System.Drawing.Drawing2D.LinearGradientMode]::Vertical)
    } else {
        $bodyBrush = [System.Drawing.SolidBrush]::new($White)
    }
    $Graphics.FillPath($bodyBrush, $tvPath)
    $bodyBrush.Dispose()

    $standBrush = [System.Drawing.SolidBrush]::new($White)
    $Graphics.FillRectangle($standBrush, 490.0, 662.0, 44.0, 42.0)
    $Graphics.FillRectangle($standBrush, 428.0, 684.0, 168.0, 40.0)
    $standBrush.Dispose()

    if ($PowerMode -eq 'punch') {
        $Graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
        $penColor = $Trans
    } else {
        $penColor = $Navy
    }

    $pen = [System.Drawing.Pen]::new($penColor, 40.0)
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round

    $ringRect = [System.Drawing.RectangleF]::new(412.0, 412.0, 200.0, 200.0)
    $Graphics.DrawArc($pen, $ringRect, -60.0, 300.0)
    $Graphics.DrawLine($pen, 512.0, 512.0, 512.0, 412.0)
    $pen.Dispose()

    if ($PowerMode -eq 'punch') {
        $Graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
    }
    $tvPath.Dispose()
}

function Save-Icon {
    param([string]$Path, [string]$Mode)

    $bmp = [System.Drawing.Bitmap]::new(1024, 1024)
    $g = New-Graphics -Bitmap $bmp
    $g.Clear($Trans)

    if ($Mode -eq 'full') {
        $bg = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
            [System.Drawing.RectangleF]::new(0, 0, 1024, 1024),
            $BgTop,
            $BgBottom,
            [System.Drawing.Drawing2D.LinearGradientMode]::Vertical)
        $g.FillRectangle($bg, 0, 0, 1024, 1024)
        $bg.Dispose()
        Draw-Glyph -Graphics $g -PowerMode 'navy' -GradientBody
    } elseif ($Mode -eq 'foreground') {
        Draw-Glyph -Graphics $g -PowerMode 'navy' -GradientBody
    } else {
        Draw-Glyph -Graphics $g -PowerMode 'punch'
    }

    $bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()
}

$script:pass = $true

function Write-Check {
    param([string]$Label, [bool]$Ok, [string]$Detail = "")
    $tag = if ($Ok) { "PASS" } else { "FAIL" }
    $script:pass = $script:pass -and $Ok
    if ($Detail) {
        Write-Output ("[{0}] {1} -- {2}" -f $tag, $Label, $Detail)
    } else {
        Write-Output ("[{0}] {1}" -f $tag, $Label)
    }
}

function Test-Navy {
    param($c)
    return (($c.A -ge 200) -and ($c.R -lt 60) -and ($c.G -lt 80) -and ($c.B -ge 55) -and ($c.B -gt $c.R))
}

function Test-White {
    param($c)
    return (($c.A -ge 200) -and ($c.R -gt 200) -and ($c.G -gt 200) -and ($c.B -gt 200))
}

function Test-Transparent {
    param($c)
    return ($c.A -lt 128)
}

function Get-GlyphBBox {
    param([System.Drawing.Bitmap]$Bitmap, [int]$Stride = 4)

    $minX = [int]::MaxValue
    $minY = [int]::MaxValue
    $maxX = -1
    $maxY = -1

    for ($y = 0; $y -lt $Bitmap.Height; $y += $Stride) {
        for ($x = 0; $x -lt $Bitmap.Width; $x += $Stride) {
            $c = $Bitmap.GetPixel($x, $y)
            if ($c.A -gt 8) {
                if ($x -lt $minX) { $minX = $x }
                if ($x -gt $maxX) { $maxX = $x }
                if ($y -lt $minY) { $minY = $y }
                if ($y -gt $maxY) { $maxY = $y }
            }
        }
    }

    if ($maxX -lt 0) {
        return $null
    }

    return @{
        MinX    = $minX
        MinY    = $minY
        MaxX    = $maxX
        MaxY    = $maxY
        CenterX = ($minX + $maxX) / 2.0
        CenterY = ($minY + $maxY) / 2.0
    }
}

function Show-AsciiMap {
    param([string]$Name, [System.Drawing.Bitmap]$Bitmap, [int]$Cells = 32)

    Write-Output ""
    Write-Output ("ASCII map {0}x{1} for {2} ('.'=transparent, 'W'=white, 'N'=navy, '?'=other):" -f $Cells, $Cells, $Name)
    $cell = 1024.0 / $Cells
    for ($r = 0; $r -lt $Cells; $r++) {
        $line = ""
        for ($c = 0; $c -lt $Cells; $c++) {
            $px = [int]($c * $cell + $cell / 2.0)
            $py = [int]($r * $cell + $cell / 2.0)
            $col = $Bitmap.GetPixel($px, $py)
            if (Test-Transparent -c $col) {
                $ch = "."
            } elseif (Test-White -c $col) {
                $ch = "W"
            } elseif (Test-Navy -c $col) {
                $ch = "N"
            } else {
                $ch = "?"
            }
            $line += $ch
        }
        Write-Output $line
    }
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$files = @(
    @{ Name = 'app_icon.png';           Mode = 'full' },
    @{ Name = 'app_icon_foreground.png'; Mode = 'foreground' },
    @{ Name = 'app_icon_monochrome.png'; Mode = 'monochrome' }
)

Write-Output "Generating icons into $OutputDir"
foreach ($f in $files) {
    $path = Join-Path $OutputDir $f.Name
    Save-Icon -Path $path -Mode $f.Mode
    Write-Output "Wrote $path"
}

$bitmaps = @{}
foreach ($f in $files) {
    $path = Join-Path $OutputDir $f.Name
    $bitmaps[$f.Name] = [System.Drawing.Bitmap]::new($path)
}

$bboxes = @{}
foreach ($f in $files) {
    $bboxes[$f.Name] = Get-GlyphBBox -Bitmap $bitmaps[$f.Name]
}

Write-Output ""
Write-Output "==================== VERIFICATION ===================="

foreach ($f in $files) {
    $name = $f.Name
    $bmp = $bitmaps[$name]
    Write-Output ""
    Write-Output ("---- {0} ----" -f $name)

    Write-Check -Label "dimensions 1024x1024" -Ok (($bmp.Width -eq 1024) -and ($bmp.Height -eq 1024)) `
        -Detail ("{0}x{1}" -f $bmp.Width, $bmp.Height)
}

$full = $bitmaps['app_icon.png']
Write-Output ""
Write-Output "---- app_icon.png color checks ----"
foreach ($pt in @(@(16, 16), @(1007, 16), @(16, 1007), @(1007, 1007))) {
    $c = $full.GetPixel($pt[0], $pt[1])
    $ok = Test-Navy -c $c
    Write-Check -Label ("corner ({0},{1}) is opaque navy" -f $pt[0], $pt[1]) -Ok $ok `
        -Detail ("RGBA={0},{1},{2},{3}" -f $c.R, $c.G, $c.B, $c.A)
}
foreach ($pt in @(@(512, 512), @(583, 583), @(441, 583))) {
    $c = $full.GetPixel($pt[0], $pt[1])
    Write-Check -Label ("power symbol ({0},{1}) is navy" -f $pt[0], $pt[1]) -Ok (Test-Navy -c $c) `
        -Detail ("RGBA={0},{1},{2},{3}" -f $c.R, $c.G, $c.B, $c.A)
}
foreach ($pt in @(@(700, 500), @(512, 680))) {
    $c = $full.GetPixel($pt[0], $pt[1])
    Write-Check -Label ("TV/stand ({0},{1}) is white" -f $pt[0], $pt[1]) -Ok (Test-White -c $c) `
        -Detail ("RGBA={0},{1},{2},{3}" -f $c.R, $c.G, $c.B, $c.A)
}
$c = $full.GetPixel(700, 700)
Write-Check -Label "background below glyph (700,700) is navy" -Ok (Test-Navy -c $c) `
    -Detail ("RGBA={0},{1},{2},{3}" -f $c.R, $c.G, $c.B, $c.A)

$fg = $bitmaps['app_icon_foreground.png']
Write-Output ""
Write-Output "---- app_icon_foreground.png checks ----"
foreach ($pt in @(@(16, 16), @(1007, 16), @(16, 1007), @(1007, 1007))) {
    $c = $fg.GetPixel($pt[0], $pt[1])
    Write-Check -Label ("corner ({0},{1}) transparent" -f $pt[0], $pt[1]) -Ok (Test-Transparent -c $c) `
        -Detail ("A={0}" -f $c.A)
}
foreach ($pt in @(@(700, 500), @(512, 680))) {
    $c = $fg.GetPixel($pt[0], $pt[1])
    Write-Check -Label ("TV/stand ({0},{1}) is white" -f $pt[0], $pt[1]) -Ok (Test-White -c $c) `
        -Detail ("RGBA={0},{1},{2},{3}" -f $c.R, $c.G, $c.B, $c.A)
}
foreach ($pt in @(@(512, 512), @(583, 583))) {
    $c = $fg.GetPixel($pt[0], $pt[1])
    Write-Check -Label ("power symbol ({0},{1}) is navy" -f $pt[0], $pt[1]) -Ok (Test-Navy -c $c) `
        -Detail ("RGBA={0},{1},{2},{3}" -f $c.R, $c.G, $c.B, $c.A)
}

$mono = $bitmaps['app_icon_monochrome.png']
Write-Output ""
Write-Output "---- app_icon_monochrome.png checks ----"
foreach ($pt in @(@(16, 16), @(1007, 16), @(16, 1007), @(1007, 1007))) {
    $c = $mono.GetPixel($pt[0], $pt[1])
    Write-Check -Label ("corner ({0},{1}) transparent" -f $pt[0], $pt[1]) -Ok (Test-Transparent -c $c) `
        -Detail ("A={0}" -f $c.A)
}
foreach ($pt in @(@(700, 500), @(512, 680))) {
    $c = $mono.GetPixel($pt[0], $pt[1])
    Write-Check -Label ("TV/stand ({0},{1}) is white" -f $pt[0], $pt[1]) -Ok (Test-White -c $c) `
        -Detail ("RGBA={0},{1},{2},{3}" -f $c.R, $c.G, $c.B, $c.A)
}
$badWhite = 0
$whiteCount = 0
for ($y = 0; $y -lt 1024; $y += 4) {
    for ($x = 0; $x -lt 1024; $x += 4) {
        $c = $mono.GetPixel($x, $y)
        if ($c.A -gt 200) {
            $whiteCount++
            if (-not (Test-White -c $c)) { $badWhite++ }
        }
    }
}
Write-Check -Label "all opaque pixels are pure white" -Ok ($badWhite -eq 0) `
    -Detail ("opaque samples={0}, non-white={1}" -f $whiteCount, $badWhite)

foreach ($pt in @(@(583, 583), @(441, 583), @(430, 512), @(594, 512), @(512, 440), @(512, 470), @(512, 512))) {
    $c = $mono.GetPixel($pt[0], $pt[1])
    Write-Check -Label ("power hole ({0},{1}) transparent" -f $pt[0], $pt[1]) -Ok (Test-Transparent -c $c) `
        -Detail ("A={0}" -f $c.A)
}

$boxX0 = 380; $boxX1 = 644; $boxY0 = 380; $boxY1 = 644
$total = 0; $trans = 0; $boxWhite = 0
for ($y = $boxY0; $y -le $boxY1; $y += 4) {
    for ($x = $boxX0; $x -le $boxX1; $x += 4) {
        $c = $mono.GetPixel($x, $y)
        $total++
        if (Test-Transparent -c $c) { $trans++ } elseif (Test-White -c $c) { $boxWhite++ }
    }
}
$frac = $trans / [double]$total
$holeOk = ($frac -gt 0.10) -and ($frac -lt 0.90) -and ($boxWhite -gt 0)
Write-Check -Label "power hole exists in middle region (380..644 box)" -Ok $holeOk `
    -Detail ("samples={0}, transparent={1} ({2:P0}), white={3}" -f $total, $trans, $frac, $boxWhite)

Write-Output ""
Write-Output "---- glyph bounding boxes (stride 4) ----"
foreach ($f in $files) {
    if ($f.Name -eq 'app_icon.png') {
        Write-Output ("[SKIP] {0} -- opaque full-bleed background; bbox is the whole canvas by design" -f $f.Name)
        continue
    }
    $name = $f.Name
    $b = $bboxes[$name]
    $inSafe = ($b.MinX -ge 174) -and ($b.MinY -ge 174) -and ($b.MaxX -le 850) -and ($b.MaxY -le 850)
    $centered = ([math]::Abs($b.CenterX - 512) -le 24) -and ([math]::Abs($b.CenterY - 512) -le 40)
    Write-Check -Label ("{0} bbox within safe zone 174..850" -f $name) -Ok $inSafe `
        -Detail ("x {0}..{1}, y {2}..{3}" -f $b.MinX, $b.MaxX, $b.MinY, $b.MaxY)
    Write-Check -Label ("{0} roughly centered on (512,512)" -f $name) -Ok $centered `
        -Detail ("center=({0:N1},{1:N1}) offset=({2:N1},{3:N1})" -f $b.CenterX, $b.CenterY, ($b.CenterX - 512), ($b.CenterY - 512))
}

$bf = $bboxes['app_icon_foreground.png']
$bm = $bboxes['app_icon_monochrome.png']
$edgeDiff = [math]::Max([math]::Max([math]::Abs($bf.MinX - $bm.MinX), [math]::Abs($bf.MaxX - $bm.MaxX)), `
                       [math]::Max([math]::Abs($bf.MinY - $bm.MinY), [math]::Abs($bf.MaxY - $bm.MaxY)))
Write-Check -Label "foreground and monochrome bboxes match" -Ok ($edgeDiff -le 20) `
    -Detail ("max per-edge diff={0}px" -f $edgeDiff)

foreach ($f in $files) {
    Show-AsciiMap -Name $f.Name -Bitmap $bitmaps[$f.Name]
}

Write-Output ""
if ($script:pass) {
    Write-Output "ALL CHECKS PASSED"
    exit 0
} else {
    Write-Output "SOME CHECKS FAILED"
    exit 1
}
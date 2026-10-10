Add-Type -AssemblyName System.Drawing

function Resize-ImageFile {
    param(
        [string]$Path,
        [int]$MaxDimension,
        [string]$Format = "JPEG",
        [int]$Quality = 85
    )

    if (-not (Test-Path $Path)) { return }
    $origBytes = (Get-Item $Path).Length
    $img = [System.Drawing.Image]::FromFile($Path)
    
    $w = $img.Width
    $h = $img.Height
    
    if ($w -le $MaxDimension -and $h -le $MaxDimension) {
        $img.Dispose()
        return
    }

    if ($w -gt $h) {
        $newW = $MaxDimension
        $newH = [int]($h * ($MaxDimension / $w))
    } else {
        $newH = $MaxDimension
        $newW = [int]($w * ($MaxDimension / $h))
    }

    $destBmp = New-Object System.Drawing.Bitmap($newW, $newH)
    $graphics = [System.Drawing.Graphics]::FromImage($destBmp)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.DrawImage($img, 0, 0, $newW, $newH)
    
    $img.Dispose()
    $graphics.Dispose()

    $tempPath = $Path + ".tmp"
    if ($Format -eq "JPEG") {
        $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
        $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
        $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]$Quality)
        $destBmp.Save($tempPath, $codec, $encoderParams)
    } else {
        $destBmp.Save($tempPath, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    $destBmp.Dispose()

    Move-Item -Path $tempPath -Destination $Path -Force
    $newBytes = (Get-Item $Path).Length
    Write-Output ("Resized {0}: {1}x{2} -> {3}x{4} | {5:N2} MB -> {6:N2} MB" -f $Path, $w, $h, $newW, $newH, ($origBytes/1MB), ($newBytes/1MB))
}

# Resize profile pictures
Resize-ImageFile -Path "assets/images/profile-1.jpg" -MaxDimension 400 -Format "JPEG" -Quality 85
Resize-ImageFile -Path "assets/images/profile-2.jpg" -MaxDimension 400 -Format "JPEG" -Quality 85
Resize-ImageFile -Path "assets/images/profile-3.jpg" -MaxDimension 400 -Format "JPEG" -Quality 85
Resize-ImageFile -Path "assets/images/profile-4.jpg" -MaxDimension 400 -Format "JPEG" -Quality 85
Resize-ImageFile -Path "assets/images/profile-5.jpg" -MaxDimension 400 -Format "JPEG" -Quality 85

# Resize app logo (from 2810x2810 to 512x512 PNG)
Resize-ImageFile -Path "assets/images/app_logo.png" -MaxDimension 512 -Format "PNG"

# Resize login_bg.png (from 1320x2916 to 720x1590)
Resize-ImageFile -Path "assets/images/login_bg.png" -MaxDimension 1280 -Format "PNG"

$assetFiles = Get-ChildItem -Path assets -Recurse -File
$dartFiles = Get-ChildItem -Path lib -Recurse -Filter *.dart
$dartContent = ($dartFiles | ForEach-Object { [System.IO.File]::ReadAllText($_.FullName) }) -join "`n"

$unused = @()
foreach ($file in $assetFiles) {
    $name = $file.Name
    if (-not $dartContent.Contains($name)) {
        $unused += [PSCustomObject]@{
            Name = $file.FullName.Replace((Get-Location).Path + "\", "")
            SizeMB = [math]::Round($file.Length / 1MB, 2)
        }
    }
}

$unused | Sort-Object SizeMB -Descending | Format-Table -AutoSize
Write-Output ("Total unused MB: {0:N2} MB" -f (($unused | Measure-Object -Property SizeMB -Sum).Sum))

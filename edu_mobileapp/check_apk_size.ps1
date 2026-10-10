Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead('build/app/outputs/flutter-apk/app-arm64-v8a-release.apk')
$entries = $zip.Entries | Sort-Object Length -Descending | Select-Object -First 35
foreach ($e in $entries) {
    $uncomp = [math]::Round($e.Length / 1MB, 2)
    $comp = [math]::Round($e.CompressedLength / 1MB, 2)
    Write-Output ("{0,10} MB  {1,10} MB  {2}" -f $uncomp, $comp, $e.FullName)
}

$sumComp = 0
$sumUncomp = 0
foreach ($e in $zip.Entries) {
    $sumComp += $e.CompressedLength
    $sumUncomp += $e.Length
}
Write-Output ("-------------------------------------------------------")
Write-Output ("Sum of compressed entries: {0:N2} MB" -f ($sumComp / 1MB))
Write-Output ("Sum of uncompressed entries: {0:N2} MB" -f ($sumUncomp / 1MB))
$zip.Dispose()

$actualSize = (Get-Item 'build/app/outputs/flutter-apk/app-arm64-v8a-release.apk').Length / 1MB
Write-Output ("Actual APK file size: {0:N2} MB" -f $actualSize)

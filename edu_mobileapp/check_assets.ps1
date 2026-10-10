Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead('build/app/outputs/flutter-apk/app-arm64-v8a-release.apk')

$assetEntries = $zip.Entries | Where-Object { $_.FullName.StartsWith('assets/') } | Sort-Object Length -Descending | Select-Object -First 40
foreach ($e in $assetEntries) {
    Write-Output ("{0,8:N2} MB (comp {1,8:N2} MB) : {2}" -f ($e.Length/1MB), ($e.CompressedLength/1MB), $e.FullName)
}
$zip.Dispose()

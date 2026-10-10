Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead('build/app/outputs/flutter-apk/app-arm64-v8a-release.apk')

$groups = @{}
foreach ($e in $zip.Entries) {
    $folder = $e.FullName.Split('/')[0]
    if (-not $groups.ContainsKey($folder)) {
        $groups[$folder] = @{ Count=0; Compressed=0; Uncompressed=0 }
    }
    $groups[$folder].Count++
    $groups[$folder].Compressed += $e.CompressedLength
    $groups[$folder].Uncompressed += $e.Length
}

foreach ($k in $groups.Keys) {
    Write-Output ("Folder {0,-25} Count: {1,5}  Comp: {2,8:N2} MB  Uncomp: {3,8:N2} MB" -f $k, $groups[$k].Count, ($groups[$k].Compressed / 1MB), ($groups[$k].Uncompressed / 1MB))
}
$zip.Dispose()

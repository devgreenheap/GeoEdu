Add-Type -AssemblyName System.Drawing

$files = Get-ChildItem -Path assets -Recurse -File | Where-Object { $_.Extension -match '\.(png|jpg|jpeg|gif|webp)' } | Sort-Object Length -Descending | Select-Object -First 25
foreach ($f in $files) {
    try {
        $img = [System.Drawing.Image]::FromFile($f.FullName)
        Write-Output ("{0,8:N2} MB  ({1,5}x{2,-5})  {3}" -f ($f.Length/1MB), $img.Width, $img.Height, $f.FullName.Replace((Get-Location).Path + "\", ""))
        $img.Dispose()
    } catch {
        Write-Output ("{0,8:N2} MB  (error)        {1}" -f ($f.Length/1MB), $f.FullName.Replace((Get-Location).Path + "\", ""))
    }
}

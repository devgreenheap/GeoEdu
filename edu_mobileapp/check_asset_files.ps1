Get-ChildItem -Path assets -Recurse -File | Sort-Object Length -Descending | Select-Object -First 30 | ForEach-Object {
    Write-Output ("{0,8:N2} MB  {1}" -f ($_.Length / 1MB), $_.FullName.Replace((Get-Location).Path + "\", ""))
}

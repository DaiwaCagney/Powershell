function ResolveAbsPath($Path) {
    return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
}

$Path=Read-Host "Enter the Relative Path"

$FullPath = ResolveAbsPath $Path

Write-Host "Absolute Path: $FullPath"

$FullPath = Resolve-Path $Path -ErrorAction SilentlyContinue -ErrorVariable err
if (!$FullPath) {
    $FullPath = $err[0].TargetObject
}

Write-Host "Absolute Path: $FullPath"

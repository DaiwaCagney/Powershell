$checkadmin = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (!$checkadmin.IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Not Administrator" -ForegroundColor Red
} else {
    Write-Host "Is Administrator" -ForegroundColor Green
}

$checkadmin = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-Not $checkadmin.IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    $CMD = $MyInvocation.Line
    $CMDARGS = $CMD.Substring($CMD.IndexOf('.ps1')+4)
    if ($CMD.StartsWith('if')) { $CMDARGS = '' }
    Start-Process Powershell -Verb RunAs -ArgumentList "$PSCommandPath $CMDARGS"
}
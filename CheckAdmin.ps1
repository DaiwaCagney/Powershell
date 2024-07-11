$checkadmin = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (!$checkadmin.IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Not Administrator" -ForegroundColor Red
} else {
    Write-Host "Is Administrator" -ForegroundColor Green
}
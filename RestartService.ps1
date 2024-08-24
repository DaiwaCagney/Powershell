param (
	[string]$ServiceName,
	[int]$Delay = 10
)

$ErrorActionPreference = 'STOP'

Write-Host "Restarting $ServiceName"
Stop-Service $ServiceName
Start-Sleep -Seconds $Delay
Start-Service $ServiceName
Write-Host "$ServiceName Restarted"
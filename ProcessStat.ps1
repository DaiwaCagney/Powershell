$logPath = "$PSScriptRoot\$(Get-Date -Format 'yyMMdd')\$(Get-Date -Format 'HHmm').csv" 

New-Item -ItemType File -Force -Path $logPath | Out-Null

Get-Process -IncludeUserName | Select-Object Id, Name, CPU, WorkingSet, UserName, Path | ConvertTo-Csv -NoTypeInformation | Out-File $logPath -Encoding UTF8

if ([System.DateTime]::Now.ToString("HH:mm") -eq "07:00") {
	$expireDate = [System.DateTime]::Today.AddMonths(-1).ToString("yyMMdd")
	Get-ChildItem -Path $PSScriptRoot -Directory |
	Where-Object { $_.Name -match "\d{6}" -and $_.Name -lt $expireDate } |
	Remove-Item -Recurse -Force
}
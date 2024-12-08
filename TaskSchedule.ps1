Param ([string]$ForceOverwrite = 'N')

$taskName = "ProcessStat"

$ErrorActionPreference = "STOP"

$chkExist = Get-ScheduledTask | Where-Object { $_.TaskName -eq $taskName }

if ($chkExist) {
    if ($ForceOverwrite -eq 'Y' -or $(Read-Host "Delete Existed [$taskName] ? (Y/N)").ToUpper() -eq 'Y') {
        Unregister-ScheduledTask $taskName -Confirm:$false # Making the operation non-interactive
    }
    else {
        Write-Host "Exit" -ForegroundColor Red
        Exit 
    }
}

$action = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument "-NoProfile -ExecutionPolicy ByPass -NonInteractive -WindowStyle Hidden -Command `"$PSScriptRoot\ProcStats.ps1`" "
$trigger = New-ScheduledTaskTrigger -Daily -At 00:00
$trigger.Repetition = (New-ScheduledTaskTrigger -Once -At 00:00 -RepetitionDuration "23:59:30" -RepetitionInterval "00:01:00").Repetition
$principle = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -TaskName $taskName -Principal $principle -Action $action -Trigger $trigger
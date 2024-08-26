Write-Host ("-" * 100)
Write-Host " "

$Groups = @(
    @(0..9),
    @(10..19),
    @(20..29),
    @(30..39),
    @(40..49)
)

$StopWatch = [System.Diagnostics.Stopwatch]::StartNew()

$JobPool = @()

$Groups | ForEach-Object {
    $Job = Start-Job -ScriptBlock {
        param ([object[]]$Array)
        $Array | ForEach-Object {
            $GUID = (New-Guid).ToString().Substring(0,8).ToUpper()
            Start-Sleep -Milliseconds (450 + (Get-Random -Minimum 1 -Maximum 50))
            return $GUID
        }
    } -ArgumentList @(, $_) 
    $JobPool += $Job
}

$JobPool | Wait-Job | Out-Null

Write-Host "Duration: $($StopWatch.ElapsedMilliseconds.ToString('n0'))ms"

$GroupNumber = 0
$JobPool | ForEach-Object {
    $Result = Receive-Job -Job $_
    $GroupNumber++
    Write-Host "Group $GroupNumber" -ForegroundColor Green
    Write-Host ($Result -join ',')
}

Write-Host " "
Write-Host ("-" * 100)
Write-Host " "

$Groups = @(
    @(0..9),
    @(10..19),
    @(20..29),
    @(30..39),
    @(40..49)
)

$ScriptBlock = {
    param ([object[]]$Array)
    $Array | ForEach-Object {
        $GUID = (New-Guid).ToString().Substring(0,8).ToUpper()
        Start-Sleep -Milliseconds (450 + (Get-Random -Minimum 1 -Maximum 50))
        return $GUID
    }
}

$Jobs = @()
$StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
$Groups | ForEach-Object {
    $RS = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $RS.Open()
    $PS = [System.Management.Automation.PowerShell]::Create()
    $PS.Runspace = $RS
    $PS.AddScript($ScriptBlock).AddArgument($_) | Out-Null
    $Jobs += [PSCustomObject]@{
        Job = $PS.BeginInvoke()
        Runspace = $RS
        PowerShell = $PS
    }    
}

while ($Jobs.Job.IsCompleted -contains $false) {
    Start-Sleep -Milliseconds 10
}
Write-Host "Duration: $($StopWatch.ElapsedMilliseconds.ToString('n0'))ms"

$GroupNumber = 0
$Jobs | ForEach-Object {
    $Result = $_.PowerShell.EndInvoke($_.Job)
    $GroupNumber++
    Write-Host "Group $GroupNumber" -ForegroundColor Green
    Write-Host ($Result -join ',')
    $_.PowerShell.Dispose()
    $_.Runspace.Close()
    $_.Runspace.Dispose()
}

Write-Host " "
Write-Host ("-" * 100)
Write-Host " "

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Collections.Concurrent

[PSCustomObject[]]$Items = @(0..49) | ForEach-Object { [PSCustomObject]@{ ID = $_; Result = $null } }

$ToDoItems = [System.Collections.Concurrent.ConcurrentQueue[object]]::new($Items)
$ProgressMessages = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()
$Results = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()

$ScriptBlock = {
    param ([ref]$ToDoItems, [ref]$Results, [ref]$ProgressMessages)

    while (-not $ToDoItems.Value.IsEmpty) {
        $Item = $null
        if (-not $ToDoItems.Value.TryDequeue([ref]$Item)) {
            continue
        }
        $GUID = (New-Guid).ToString().Substring(0, 8).ToUpper()
        Write-Output "$GUID"
        $Item.Result = $GUID
        $Results.Value.Enqueue($Item)
        $ProgressMessages.Value.Enqueue("Generated: $guid")
        Start-Sleep -Milliseconds (450 + (Get-Random -Minimum 1 -Maximum 50))
    }
}

$Time = (Measure-Command {
    $Jobs = @()
    (1..5) | ForEach-Object {
        $RS = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
        $RS.Open()
        $PS = [System.Management.Automation.PowerShell]::Create()
        $PS.Runspace = $RS
        $PS.AddScript($ScriptBlock).AddArgument([ref]$TodoItems).AddArgument([ref]$Results).AddArgument([ref]$ProgressMessages) | Out-Null
        $Jobs += [PSCustomObject]@{
            Job = $PS.BeginInvoke()
            Runspace = $RS
            PowerShell = $PS
        }
    }
    while ($Jobs.Job.IsCompleted -contains $false) {
        while (-not $ProgressMessages.IsEmpty) {
            $Message = $null
            if ($ProgressMessages.TryDequeue([ref]$Message)) 
            {
                Write-Host "$([DateTime]::Now.ToString('HH:mm:ss.fff')) $Message"
            }
        }
        Start-Sleep -Milliseconds 100
    }
}).TotalMilliseconds

Write-Host "Duration: $($Time.ToString('n0'))ms"

$GroupNumber = 0

$Jobs | ForEach-Object {
    $Result = $_.PowerShell.EndInvoke($_.Job)
    $GroupNumber++
    Write-Host "Group $GroupNumber" -ForegroundColor Green
    Write-Host ($Result -join ',')
    $_.PowerShell.Dispose()
    $_.Runspace.Close()
    $_.Runspace.Dispose()
}

Write-Host "Results Queue: " -ForegroundColor Yellow
($Results.ToArray() | ForEach-Object {
    $_.Result
}) -join ','

Write-Host " "
Write-Host ("-" * 100)
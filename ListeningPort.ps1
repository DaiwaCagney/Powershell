$dict=@{}
Get-WmiObject Win32_Process | ForEach-Object {
    $path=$_.ExecutablePath
    if (!$path) {
        $path = $_.Name
    }
    $dict['P'+$_.ProcessId]=$path+' '+$_.CommandLine
}

Get-NetTCPConnection -State Listen | Sort-Object {$_.LocalPort} | ForEach-Object {
    $process=Get-Process -Id $_.OwningProcess
    $processpath=$process.Path
    $socket="$($_.LocalAddress):$($_.LocalPort)"
    if (!$processpath) {
        $processpath=$dict['P'+$process.Id]
    }
    [PSCustomObject]@{
        Process = $process.Name
        PID = $process.Id
        Socket = $socket
        Path = $processpath
    }
}
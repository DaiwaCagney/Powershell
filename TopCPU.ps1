param (
    [Parameter(Mandatory=$true)]
    [string]$HHmm
)

$ErrorActionPreference = 'STOP'

$time = [DateTime]::ParseExact($HHmm, 'HHmm', $null)

$lastMin = $time.AddMinutes(-1).ToString('HHmm')

$lastCpu = @{}

Import-Csv "$lastMin.csv" | ForEach-Object {
    $lastCpu['P' + $_.Id] = $_
}

$data = Import-Csv "$HHmm.csv"

$data | ForEach-Object {
    $lastData = $lastCpu['P' + $_.Id]
    if ($lastData) {
        $_.CPU = [float]$_.CPU - [float]$lastData.CPU
    }
    return $_
} | Sort-Object -Descending { $_.CPU }
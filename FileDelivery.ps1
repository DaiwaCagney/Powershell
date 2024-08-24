$ErrorActionPreference = 'Stop'

$TargetPath = Join-Path $PSScriptRoot 'Source'

if (-not (Test-Path $TargetPath)) {
    New-Item -Path $TargetPath -ItemType Directory
}

$Watcher = New-Object System.IO.FileSystemWatcher -ArgumentList $TargetPath, $Filter -Property @{
    Filter = '*.*'
    IncludeSubdirectories = $false
    EnableRaisingEvents = $true
}

$global:Mapping = @{
    '.txt' = Join-Path $PSScriptRoot 'Text'
    '.html' = Join-Path $PSScriptRoot 'Text'
    '.xml' = Join-Path $PSScriptRoot 'Text'
    '.jpg' = Join-Path $PSScriptRoot 'Image'
    '.png' = Join-Path $PSScriptRoot 'Image'
    '.gif' = Join-Path $PSScriptRoot 'Image'
    '.pdf' = Join-Path $PSScriptRoot 'PDF'
    '.mp3' = Join-Path $PSScriptRoot 'Music'
    '.mp4' = Join-Path $PSScriptRoot 'Video'
}

$SourceID = 'FileChanged'

Register-ObjectEvent $Watcher Created -SourceIdentifier $SourceID -Action {
    $FilePath = $Event.SourceEventArgs.FullPath
    $Extension = [System.IO.Path]::GetExtension($FilePath)
    $OtherPath = Join-Path $PSScriptRoot 'Other'

    if ($global:Mapping.ContainsKey($Extension)) {
        try {
            Move-Item -Path $FilePath -Destination $global:Mapping[$Extension] -Force
            Write-Host "$FilePath Moved to $($global:Mapping[$Extension])"
        }
        catch {
            Write-Host $_.Exception.Message
        }
    } else {
        Write-Host "Unknown file type: $Extension"
        Move-Item -Path $FilePath -Destination $OtherPath -Force
    }
} | Out-Null

try {
    while ($true) {
        Wait-Event -SourceIdentifier $SourceID
    }
} finally {
    Unregister-Event -SourceIdentifier $SourceID
    $Watcher.Dispose()
}
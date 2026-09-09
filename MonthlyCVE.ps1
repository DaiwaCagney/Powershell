$URL = "https://serpapi.com/search"

$Param = @{
    "engine" = "google_trends"
    "q"="CVE"
    "data_type"="RELATED_QUERIES"
    "api_key"=""
    "hl"="en"
    "date"="now 7-d"
}

do {
    $response = Invoke-RestMethod -Uri $URL -Method Get -Body $Param
} while (-not $?)

$rising = $response.related_queries.rising

$ThisMonth = Get-Date -format "yyyyMM"

$ThisYear = $ThisMonth.Substring(0, 4)

$filePath = ".\$ThisMonth.txt"

$pattern = "(?i)^CVE-$ThisYear-\d{4,5}$"

if (Test-Path -Path $filePath) {
    $FileRecords = Get-Content -Path $filePath
    Write-Host $FileRecords
    $rising | ForEach-Object {
        Write-Host $_
        if ($_.value -eq "Breakout") {
            if ($_.query -match $pattern) {
                $cve = $_.query
                $CVEUpper = $cve.ToUpper()
                Write-Host $CVEUpper
                if ($FileRecords) {
                    if (-not $FileRecords.Contains($CVEUpper)) {
                        Add-Content -Path $filePath -Value $CVEUpper
                    }
                }
                else {
                    Add-Content -Path $filePath -Value $CVEUpper
                }
            }
        }
    }
} else {
    New-Item -Path $filePath -ItemType File
    $rising | ForEach-Object {
        if ($_.value -eq "Breakout") {
            if ($_.query -match $pattern) {
                $cve = $_.query
                $CVEUpper = $cve.ToUpper()
                Add-Content -Path $filePath -Value $CVEUpper
            }
        }
    }
}

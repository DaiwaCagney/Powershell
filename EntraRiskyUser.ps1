$ErrorActionPreference = "SilentlyContinue"

$apiUrl = "https://api.abuseipdb.com/api/v2/check"
$apiKey = ""

$headers = @{
    "Key"    = $apiKey
    "Accept" = "application/json"
}

$Today = Get-Date -Format ("ddMMyyyy")
$DaysToCheck = 7
$CheckDate = (Get-Date).AddDays(-$DaysToCheck).ToString("yyyy-MM-dd")

$OneIPForAccounts = @{}
$OneAccountforDests = @{}
$Over20 = @{}
$IPInfo = @{}
$SMTP = @{}

$AllContent = Get-Content RiskyUser.txt

$Users = @()

for ($i = 0; $i -lt $AllContent.Count; $i += 5) {
    $DisplayName = $AllContent[$i]
    $UPN = $AllContent[$i + 1]
    $Status = $AllContent[$i + 2]

    $Users += [PSCustomObject]@{
        DisplayName = $DisplayName.Trim()
        UPN         = $UPN.Trim()
        Status      = $Status.Trim()
        Reason      = ""
    }
}

foreach ($User in $Users) {
    if ($User.Status -eq "Confirmed compromised") {
        $User.Reason += "Admin confirmed user compromised "
    }
}

Write-Host "Total $($Users.Count) Users" -ForegroundColor Green

Connect-AzureAD
Write-Host "Login Successful"
Write-Host "Searching for the login record after $CheckDate"

foreach ($User in $Users) {
    Write-Host "For $($User.DisplayName)" -ForegroundColor Cyan
    $FilterStr = "userPrincipalName eq '$($User.UPN)' and createdDateTime ge $CheckDate and status/errorCode eq 0"
    
    do {
        Start-Sleep -Milliseconds 500
        $AllLogins = Get-AzureADAuditSignInLogs -Filter $FilterStr -All $true
    } while (-not $?)

    foreach ($loginrecord in $AllLogins) {
        $UTCString = $loginrecord.CreatedDateTime
        $UTCDateTime = [DateTime]::Parse($UTCString)
        $LocalDate = $UTCDateTime.ToLocalTime()
        $LoginDate = $LocalDate.ToString("yyyy-MM-dd HH:mm")

        $LoginName = $loginrecord.UserDisplayName
        $NetID = $loginrecord.UserPrincipalName
        $LoginIP = $loginrecord.IpAddress
        $ClientApp = $loginrecord.ClientAppUsed

        $City = $loginrecord.Location.City
        $State = $loginrecord.Location.State
        $Country = $loginrecord.Location.CountryOrRegion
        $FullAddress = "$Country $State $City"

        if (-not $IPInfo.ContainsKey($LoginIP)) {
            $params = @{
                ipAddress = $LoginIP
            }
            $IPResult = Invoke-WebRequest -Uri $apiUrl -Method Get -Headers $headers -Body $params
            $IPdata = $IPResult.Content | ConvertFrom-Json
            $IPInfo[$LoginIP] = $IPdata.data.abuseConfidenceScore
        }

        $COA = $IPInfo[$LoginIP]

        if ($Country -ne "HK") {

            if (-not $OneIPForAccounts.ContainsKey($LoginIP)) {
                $OneIPForAccounts[$LoginIP] = @()
            }

            if (-not $OneIPForAccounts[$LoginIP].Contains($NetID)) {
                $OneIPForAccounts[$LoginIP] += $NetID
            }

            if (-not $OneAccountforDests.ContainsKey($NetID)) {
                $OneAccountforDests[$NetID] = @()
            }

            if (-not $OneAccountforDests[$NetID].Contains($Country)) {
                $OneAccountforDests[$NetID] += $Country
            }

            if (-not $Over20.ContainsKey($NetID)) {
                $Over20[$NetID] = @()
            }

            if (-not $SMTP.ContainsKey($NetID)) {
                $SMTP[$NetID] = @()
            }

            $COANum = [int]$COA
            if ($COANum -ge 20) {
                $Over20[$NetID] += $LoginIP
                if ($ClientApp -match "SMTP") {
                    $SMTP[$NetID] += $LoginIP
                    $User.Reason += "$LoginIP ($COA%) SMTP "
                }
                else {
                    $User.Reason += "$LoginIP ($COA%) "
                }
            }
        }

        $row = [PSCustomObject]@{
            Date     = $LoginDate
            Name     = $LoginName
            NetID    = $NetID
            IP       = $LoginIP
            COA      = $COA
            APP      = $ClientApp
            Location = $FullAddress
        }

        $row | Export-Csv -Path ".\RiskyUser_Logins_$Today.csv" -NoTypeInformation -Append
    }
}

Write-Host " "
Write-Host " "
Write-Host "****************************** Confidence of Abuse > 20 ******************************"
foreach ($key in $Over20.Keys) {
    if ($Over20[$key].Length -gt 0) {
        Write-Host "$key $($Over20[$key] -join ', ')"  -ForegroundColor Green
    }
}

Write-Host " "
Write-Host " "
Write-Host "****************************** One IP login multiple accounts ******************************"
foreach ($key in $OneIPForAccounts.Keys) {
    if ($OneIPForAccounts[$key].Length -gt 2) {
        Write-Host "$key $($OneIPForAccounts[$key] -join ', ')"
        foreach ($value in $OneIPForAccounts[$key]) {
            $TargetUser = $Users | Where-Object { $_.UPN -eq $value }
            if ($TargetUser) {
                $TargetUser.Reason += "One IP login multiple accounts $key "
            }
        }
    }
}

Write-Host " "
Write-Host " "
Write-Host "****************************** One account login in multiple Destination ******************************"
foreach ($key in $OneAccountforDests.Keys) {
    if ($OneAccountforDests[$key].Length -gt 2) {
        $joinedValues = $OneAccountforDests[$key] -join ', '
        Write-Host "$key $joinedValues"
        $TargetUser = $Users | Where-Object { $_.UPN -eq $key }
        if ($TargetUser) {
                $TargetUser.Reason += "Multiple Countries within one week $joinedValues "
        }
    }
}

Write-Host " "
Write-Host " "
Write-Host "****************************** SMTP Login ******************************"
foreach ($key in $SMTP.Keys) {
    if ($SMTP[$key].Length -gt 0) {
        Write-Host "$key $($SMTP[$key] -join ', ')"
    }
}

Write-Host " "
Write-Host " "

Disconnect-AzureAD
Write-Host "Disconnected"

$Users | Format-Table -AutoSize

$Users | Where-Object { $_.Reason -ne "" } | Export-Csv -Path ".\FlaggedRiskyUsers_$Today.csv" -NoTypeInformation -Encoding UTF8

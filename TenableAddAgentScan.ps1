# Config Info
$NessusManagerURL = "https://nessus-manager.example.com"
$AccessKey        = ""
$SecretKey        = ""
$AuthHeader = "X-ApiKeys: accessKey=$AccessKey; secretKey=$SecretKey"

$TenableSCURL = "tenable-sc.example.com"
$AccessKeySC = ""
$SecretKeySC = ""
$AuthHeaderSC = "x-apikey: accesskey=$AccessKeySC; secretkey=$SecretKeySC"
$TenableSCScanURL = "https://$TenableSCURL/rest/agentScan"

$NessusManagerId = 123
$RepositoryId = 456
$PolicyId = 789
$ReportId = 101

$ScriptDir = $PSScriptRoot
$FilePath = Join-Path -Path $ScriptDir -ChildPath "AgentIPList.txt"
$IPList = Get-Content $FilePath | Where-Object { $_.Trim() -ne "" }

[int]$ReportNumber = Read-Host "Enter the first report number"

$SuccessList  = @()
$HostnameList = @()
$NotExistList = @()
$OfflineList  = @()
$FailedList   = @()

$LaunchAfter = Read-Host "Would you like to launch the scan after create (yes/no)"

# Create Scan
foreach ($IP in $IPList) {
    $IP = $IP.Trim()
    Write-Host "`nProcessing IP: $IP" -ForegroundColor Cyan

    try {
        $SearchEndpoint = "/agents?filter.0.filter=ip&filter.0.quality=eq&filter.0.value=$IP"
        $SearchUrl = "$NessusManagerURL$SearchEndpoint"
        
        $SearchOutput = curl.exe -s -k -X GET -H "Content-Type: application/json" -H $AuthHeader "$SearchUrl"
        $SearchResponse = $SearchOutput | ConvertFrom-Json

        if (-not $SearchResponse.agents -or $SearchResponse.agents.Count -eq 0) {
            Write-Host " - Agent not found" -ForegroundColor Yellow
            $NotExistList += $IP
            continue
        }

        $Agent = $SearchResponse.agents[0]
        $AgentId = $Agent.id
        $AgentStatus = $Agent.status
        $AgentName = $Agent.name

        if ($AgentStatus -ne "online") {
            Write-Host " - Agent exists but is offline" -ForegroundColor Yellow
            $OfflineList += $IP
            continue
        }

        Write-Host " -> Agent is online. Creating group..." -ForegroundColor Green

        $GroupName = "Group_${IP}"
        $CreateGroupUrl = "$NessusManagerURL/agent-groups"
        $GroupPayload = "{`"name`":`"$GroupName`"}"
        
        $CreateGroupOutput = $GroupPayload | curl.exe -s -k -X POST -H "Content-Type: application/json" -H $AuthHeader -d "@-" "$CreateGroupUrl"
        $CreateGroupResponse = $CreateGroupOutput | ConvertFrom-Json

        if (-not $CreateGroupResponse.id) {
            Write-Host " -> Error creating group '$GroupName'." -ForegroundColor Red
            $CheckGroupOutput = curl.exe -s -k -X GET -H "Content-Type: application/json" -H $AuthHeader "$CreateGroupUrl"
            $CheckGroupResponse = $CheckGroupOutput | ConvertFrom-Json
            $targetGroup = $CheckGroupResponse.groups | Where-Object { $_.name -eq $GroupName }
            $GroupId = $targetGroup.id
        } else {
            $GroupId = $CreateGroupResponse.id
        }
        
        Write-Host " - Group '$GroupName' (ID: $GroupId). Adding agent to group..." -ForegroundColor Green

        $AddAgentUrl = "$NessusManagerURL/agent-groups/$GroupId/agents/$AgentId"
        
        $AddAgentOutput = curl.exe -s -k -X PUT -H "Content-Type: application/json" -H $AuthHeader -d "{}" "$AddAgentUrl"
        
        if ($AddAgentOutput -match "error") {
            Write-Host " -> Failed to add agent to group." -ForegroundColor Yellow
        }

        $FormattedNumber = $ReportNumber.ToString("0000")
        $ScanName = "$FormattedNumber"+"_$IP"
        $ReportNumber = $ReportNumber+1

        $ScanPayload = @{
            name          = $ScanName
            type          = "policy"
            description   = ""
            nessusManager = @{
                id = $NessusManagerId
            }
            repository    = @{
                id = $RepositoryId
            }
            scanWindow    = "1440"
            policy        = @{
                id = $PolicyId
            }
            agentGroups   = @(
                @{
                    id = $GroupId
                }
            )
            schedule      = @{
                type = "template"
            }
            reports       = @(
                @{
                    id           = $ReportId
                    reportSource = "individual"
                }
            )
        }

        $ScanJsonPayload = $ScanPayload | ConvertTo-Json -Depth 5 -Compress

        Write-Host "Sending request to create Agent Scan..." -ForegroundColor Cyan

        $CreateScanOutput = $ScanJsonPayload | curl.exe -s -k -X POST -H "Content-Type: application/json" -H $AuthHeaderSC -d "@-" "$TenableSCScanURL"
        $CreateScanResponse = $CreateScanOutput | ConvertFrom-Json

        if (-not $CreateScanResponse.response.id) {
            Write-Host " - Create Scan Failed" -ForegroundColor Red
            $FailedList += $IP
            continue
        }

        $ScanID = $CreateScanResponse.response.id

        if ( $LaunchAfter -eq "yes") {
            $TenableSCLaunchURL = "https://$TenableSCURL/rest/agentScan/$ScanID/launch"
            $LaunchScanOutput = curl.exe -s -k -X POST -H "Content-Type: application/json" -H $AuthHeaderSC "$TenableSCLaunchURL"
            $LaunchScanResponse = $LaunchScanOutput | ConvertFrom-Json
            if ($LaunchScanResponse.error_code -eq 0) {
                Write-Host " - Scan Created and Launched" -ForegroundColor Green
            } else {
                Write-Host " - Launch failed" -ForegroundColor Green
            }
        } else {
            Write-Host " - Scan Created (but not launched)" -ForegroundColor Green
        }

        $SuccessList += $IP
        $HostnameList += $AgentName

    } catch {
        Write-Host " -> Unexpected error processing IP: $($_.Exception.Message)" -ForegroundColor Red
        $FailedList += $IP
    }
}

Write-Host "`n=======================================================" -ForegroundColor Magenta
Write-Host "                   SUMMARY REPORT                      " -ForegroundColor Magenta
Write-Host "=======================================================" -ForegroundColor Magenta

Write-Host "`n[agent that created group successfully]" -ForegroundColor Green
if ($SuccessList.Count -gt 0) {
    $SuccessList | ForEach-Object { Write-Host " - $_" }
} else {
    Write-Host " (None)" -ForegroundColor DarkGray
}

Write-Host "`n[Hostname List]" -ForegroundColor Green
if ($HostnameList.Count -gt 0) {
    $HostnameList | ForEach-Object { Write-Host "$_" }
} else {
    Write-Host " (None)" -ForegroundColor DarkGray
}

Write-Host "`n[agent that not exist]" -ForegroundColor Red
if ($NotExistList.Count -gt 0) {
    $NotExistList | ForEach-Object { Write-Host " - $_" }
} else {
    Write-Host " (None)" -ForegroundColor DarkGray
}

Write-Host "`n[agent that is offline]" -ForegroundColor Yellow
if ($OfflineList.Count -gt 0) {
    $OfflineList | ForEach-Object { Write-Host " - $_" }
} else {
    Write-Host " (None)" -ForegroundColor DarkGray
}

Write-Host "`n[agent that is not add to group successfully (any other reasons)]" -ForegroundColor Cyan
if ($FailedList.Count -gt 0) {
    $FailedList | ForEach-Object { Write-Host " - $_" }
} else {
    Write-Host " (None)" -ForegroundColor DarkGray
}

Write-Host "`n=======================================================" -ForegroundColor Magenta

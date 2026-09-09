$TenableSCURL = "tenable-sc.example.com"
$AccessKeySC = ""
$SecretKeySC = ""
$AuthHeaderSC = "x-apikey: accesskey=$AccessKeySC; secretkey=$SecretKeySC"
$TenableSCScanResutlURL = "https://$TenableSCURL/rest/scanResult"
$TenableSCanalysisURL = "https://$TenableSCURL/rest/analysis"
$ExceptionURL = "https://$TenableSCURL/rest/acceptRiskRule"
$RepositoryId = 456

$agentIP = Read-Host "Enter the Agent IP Address"

$ScanListOutput = curl.exe -s -k -X GET -H "Content-Type: application/json" -H $AuthHeaderSC "$TenableSCScanResutlURL"
$ScanListResponse = $ScanListOutput | ConvertFrom-Json

$allScans = $ScanListResponse.response.usable
$filteredScans = $allScans | Where-Object { $_.name -match [regex]::Escape($agentIP) }
$selectedScan = $filteredScans[0]

$analysisPayload = @{
    type        = "vuln"
    sourceType  = "individual"
    scanID      = [int]$selectedScan.id
    view        = "all"
    sortField   = "severity"
    query       = @{
        type        = "vuln"
        scanID      = [int]$selectedScan.id
        tool        = "vulndetails" 
        startOffset = 0
        endOffset   = 300
        sortColumn  = "severity"
        sortDirection = "desc"
    }
}

$analysisjsonBody = $analysisPayload | ConvertTo-Json -Depth 5

$ScanResultOutput = $analysisjsonBody | curl.exe -s -k -X POST -H "Content-Type: application/json" -H $AuthHeaderSC -d "@-" "$TenableSCanalysisURL"
$ScanListResponse = $ScanResultOutput | ConvertFrom-Json
$filteredVulns = $ScanListResponse.response.results | Where-Object {($_.pluginText -like "*/opt/splunkforwarder*") -and ($_.severity.id -ne 0)}

$agentUUID = $filteredVulns[0].uuid

foreach ($vuln in $filteredVulns) {
    Write-Host "Plugin ID: $($vuln.pluginID) - $($vuln.pluginName)"
}

$ConfirmExcept = Read-Host "Confirm to perform exception, input (yes)"

if ($ConfirmExcept -eq "yes") {
    $ExRuleOutput = curl.exe -s -k -X GET -H "Content-Type: application/json" -H $AuthHeaderSC "$ExceptionURL"
    $ExRuleResponse = $ExRuleOutput | ConvertFrom-Json
    $targetExRules = $ExRuleResponse.response | Where-Object {$_.hostValue -eq $agentUUID}
    foreach ($vuln in $filteredVulns) {
        $targetPlugin = $vuln.pluginID
        if ($targetExRules.plugin.id -notcontains $targetPlugin) {
            Write-Host "Target plugin $targetPlugin was NOT found. Proceeding..." -ForegroundColor Green
            $acceptRiskPayload = @{
                repositories = @(
                    @{ id = $RepositoryId }
                )
                plugin       = @{
                    id = [int]$targetPlugin
                }
                hostType     = "uuid"
                hostValue    = $agentUUID
                comments     = "Splunk Forwarder"
            }
            
            $acceptRiskjsonBody = $acceptRiskPayload | ConvertTo-Json -Depth 5

            try {
                $AddAcceptOutput = $acceptRiskjsonBody | curl.exe -s -k -X POST -H "Content-Type: application/json" -H $AuthHeaderSC -d "@-" "$ExceptionURL"
                $AddAcceptResponse = $AddAcceptOutput | ConvertFrom-Json
                Write-Host "Successfully created Accept Risk Rule for $targetPlugin - $($AddAcceptResponse.response.id)" -ForegroundColor Green
            }
            catch {
                Write-Host "Failed to create Accept Risk Rule: $_" -ForegroundColor Red
                if ($_.ErrorDetails) {
                    Write-Host "Error Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
                }
            }
        }
        else {
            Write-Host "Target plugin $targetPlugin WAS found in the results. Stopping." -ForegroundColor Yellow
        }
    }
}

Write-Host "For UUID $agentUUID" -ForegroundColor Green

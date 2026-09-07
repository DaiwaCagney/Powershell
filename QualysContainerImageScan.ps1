# Config
$username = "<QUALYS_USERNAME>"
$password = Read-Host -Prompt "Enter your password" -AsSecureString
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
$password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
$registryId = "<QUALYS_REGISTRY_ID>"
$registryName = "<REGISTRY_NAME>"
$registryUri = "registry.example.com"
$recipientEmail = "team@example.com"

$QualysAPIUri = "https://qualys-api.example.com"
$authUrl = "https://qualys-auth.example.com"
$registryACUrl = "$QualysAPIUri/registry/$registryId"
$ImageUrl = "$QualysAPIUri/images"
$ScanUrl = "$QualysAPIUri/registry/$registryId/schedule"
$ReportUrl = "$QualysAPIUri/reports"

$ocusername = "<OKD_USERNAME>"
$ocpassword = Read-Host -Prompt "Enter your OKD password" -AsSecureString
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ocpassword)
$ocpassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
$ocUrl = "https://api.okd.example.com:6443"

$dateString = Get-Date -Format "yyyyMMdd"
[int]$ReportNumber = Read-Host "Enter the first report number"
$FormattedNumber = $ReportNumber.ToString("0000")
$numberofscan = Read-Host "number of scan (press Enter to skip, 1 for the second times and so on)"

# Auth
$body = @{
    username = $username
    password = $password
    token    = "true"
}

$headers = @{
    "Content-Type" = "application/x-www-form-urlencoded"
}

try {
    $response = Invoke-RestMethod -Uri $authUrl -Method Post -Headers $headers -Body $body
    Write-Host "Authentication Successful!" -ForegroundColor Green
    $jwtToken = $response
} catch {
    Write-Error "Authentication failed. Error details:"
    Write-Error $_.Exception.Message
}

oc login -u $ocusername -p $ocpassword $ocUrl --insecure-skip-tls-verify=true
if ($LASTEXITCODE -eq 0) {
    Write-Host "Successfully logged in to OKD cluster!" -ForegroundColor Green
    $ocToken = oc whoami -t
    Write-Host "Token retrieved successfully."
} else {
    Write-Error "Failed to log in to the cluster."
    exit 1
}

[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
$password = $null
$ocpassword  = $null

$b64User  = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($ocusername))
$b64Token = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($ocToken))

$payload = @{
    credential = @{
        username = $b64User
        password  = $b64Token
    }
    credentialType = "BasicAuth"
    registryType   = "V2_PRIVATE"
    registryUri    = $registryUri
    registryName   = $registryName
}

$jsonBody = $payload | ConvertTo-Json -Depth 5 -Compress

$headers = @{
    "Accept"        = "application/json"
    "Content-Type"  = "application/json"
    "Authorization" = "Bearer $jwtToken"
}

try {
    $response = Invoke-RestMethod -Uri $registryACUrl -Method Put -Headers $headers -Body $jsonBody
    Write-Host "Registry updated successfully in Qualys!" -ForegroundColor Green
} catch {
    Write-Error "HTTP Error Code: $($_.Exception.Response.StatusCode)"
    Write-Error $_.Exception.Message
}

## Scan
$Repobase = "<OKD_PROJECT>"
$targetedImage = Read-Host -Prompt "Target Image"
$targetRepo = "$Repobase/$targetedImage"
$targetTag  = Read-Host -Prompt "Target Image Tag"

if ([string]::IsNullOrWhiteSpace($numberofscan)) {
    $scan_name = "$FormattedNumber"+"_ContainerImagesScan"+"_$targetedImage"+"_$dateString"
    $reportName = "$FormattedNumber"+"_ContainerImageScanReport"+"_$targetedImage"+"_$dateString"
} else {
    $scan_name = "$FormattedNumber"+"-$numberofscan"+"_ContainerImagesScan"+"_$targetedImage"+"_$dateString"
    $reportName = "$FormattedNumber"+"-$numberofscan"+"_ContainerImageScanReport"+"_$targetedImage"+"_$dateString"
}

$payload = @{
    name      = $scan_name
    onDemand  = $true
    forceScan = $true
    filters   = @(
        @{
            repoTags = @(
                @{
                    repo = $targetRepo
                    tag  = $targetTag
                }
            )
        }
    )
}

$jsonBody = $payload | ConvertTo-Json -Depth 5 -Compress

try {
    $response = Invoke-RestMethod -Uri $ScanUrl -Method Post -Headers $headers -Body $jsonBody
    Write-Host "On-demand scan triggered successfully!" -ForegroundColor Green
    $ScanUUID = $response.scheduleUuid
} catch {
    Write-Error "Failed to trigger scan."
    Write-Error "HTTP Status: $($_.Exception.Response.StatusCode)"
    Write-Error $_.Exception.Message
}

$CheckScanUrl = "$QualysAPIUri/registry/$registryId/schedule/$ScanUUID/executions"

$isScanComplete = $false
$maxRetries = 40
$retryCount = 0

Write-Host "Starting loop to check scan status every 3 minutes..." -ForegroundColor Cyan

while (-not $isScanComplete -and $retryCount -lt $maxRetries) {
    try {
        $response = Invoke-RestMethod -Uri $CheckScanUrl -Method Get -Headers $headers
        $status = $response.data.status 
        
        if ($status -eq "Finished") {
            Write-Host "Scan completed successfully!" -ForegroundColor Green
            $isScanComplete = $true
        } elseif ($status -eq "Canceled" -or $status -eq "Error") {
            Write-Error "The scan execution failed in Qualys."
            exit 1
        } else {
            $retryCount++
            Write-Host "Scan is still in progress. Waiting 3 minutes before checking again..."
            Start-Sleep -Seconds 180
        }
    } catch {
        Write-Warning "Failed to fetch status. Retrying in 3 minutes... Error: $_"
        $retryCount++
        Start-Sleep -Seconds 180
    }
}

if (-not $isScanComplete) {
    Write-Error "Scan timed out"
    exit 1
}

# Image
$response = Invoke-RestMethod -Uri $ImageUrl -Method Get -Headers $headers
$targetImage = $response.data | Where-Object { $_.repo.repository -eq $targetRepo -and $_.repo.tag -eq $targetTag }
$targetDigest = $targetImage.repoDigests[0].digest

# Report
Write-Host "Proceeding to generate and email the report..." -ForegroundColor Cyan

$reportPayload = @{
    name              = $reportName
    description       = "For $targetedImage"
    templateName      = "CS_IMAGE_VULNERABILITY"
    filter            = "container.image.repoDigest.digest:$targetDigest" 
    displayColumns    = @(
        "imageId","label","tags","qid","title","severity","cveids","vendorReference","cvss3Base","threat","impact","solution","category","software","result"
    )
    emailNotification = 1
    sendAsAttachment  = 1
    expireAfter = 1
    zip = 0
    recipient         = $recipientEmail
    emailSubject      = "Qualys Scan Complete: $targetedImage"
    customMessage     = "Just to Say Hi"
    includeScaVuln    = $true
}

$reportjsonBody = $reportPayload | ConvertTo-Json -Depth 10

$response = Invoke-RestMethod -Uri $ReportUrl -Method Post -Headers $headers -Body $reportjsonBody

Write-Host "Completed"
Write-Host "$targetRepo : $targetTag"
Write-Host "$targetDigest"

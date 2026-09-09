$sonarQubeUrl = "https://sonarqube.example.com/api"
$token = ""
$issueType = "SECURITY"
$projectKey = Read-Host "Please input Project Key"
$branch = Read-Host "Please input branch, if main branch press enter to skip"
$dateTime = Get-Date -Format "yyyy-MM-dd HH-mm-ss"
$currentPath = Get-Location
$CSVName = "$projectKey $datetime.csv"
$secHotspotCSVName = "$projectKey SecHotspot $datetime.csv"

if ([string]::IsNullOrWhiteSpace($branch)) {
    $projectInfoUrl = "$sonarQubeUrl/issues/search?components=$projectKey&impactSoftwareQualities=$issueType&ps=500&additionalFields=comments"
    $secHotspotUrl = "$sonarQubeUrl/hotspots/search?project=$projectKey&ps=500"
}
else {
    $branch = $branch.Trim()
    $projectInfoUrl = "$sonarQubeUrl/issues/search?components=$projectKey&impactSoftwareQualities=$issueType&ps=500&branch=$branch&additionalFields=comments"
    $secHotspotUrl = "$sonarQubeUrl/hotspots/search?project=$projectKey&ps=500&branch=$branch"
}
 
$headers = @{
    'Authorization' = "Bearer $token"
}

$response = Invoke-RestMethod -Uri $projectInfoUrl -Headers $headers -Method Get
$secHotspotResponse = Invoke-RestMethod -Uri $secHotspotUrl -Headers $headers -Method Get

$response.issues | Foreach-Object {
    $project=$_.project
    $rule=$_.rule
    $ruleUrl="$sonarQubeUrl/rules/search?rule_key=$rule"
    $ruleResponse = Invoke-RestMethod -Uri $ruleUrl -Headers $headers -Method Get
    $ruleName=$ruleResponse.rules.name
    $ruleLang=$ruleResponse.rules.langName
    $severity=$_.impacts.severity
    $message=$_.message
    $component=$_.component
    $componentFilePath=($component -split ':')[1]
    $line=$_.line
    $textRange=$_.textRange
    $issueStatus=$_.issueStatus
    $comment=$_.comments.htmltext
    if ($comment -isnot [string]) {
        $comment = $comment[-1]
    }

    $toHashString="$rule$componentFilePath$line"
    $byteArray = [System.Text.Encoding]::UTF8.GetBytes($toHashString)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $hashBytes = $sha256.ComputeHash($byteArray)
    $hashString = [BitConverter]::ToString($hashBytes) -replace '-', ''

    $row = [PSCustomObject]@{
        Project = $project
        RuleKey = $rule
        RuleName = $ruleName
        Language = $ruleLang
        Severity = $severity
        Remediation = $message
        FilePath = $componentFilePath
        Line = $line
        TextRange = $textRange
        Status = $issueStatus
        CompareKey = $hashString
        Comment = $comment
    }

    $row | Export-Csv -Path "$currentPath\$CSVName" -NoTypeInformation -Append
}

$secHotspotResponse.hotspots | Foreach-Object {
    $project=$_.project
    $rule=$_.ruleKey
    $ruleUrl="$sonarQubeUrl/rules/search?rule_key=$rule"
    $ruleResponse = Invoke-RestMethod -Uri $ruleUrl -Headers $headers -Method Get
    $ruleName=$ruleResponse.rules.name
    $ruleLang=$ruleResponse.rules.langName
    $probability=$_.vulnerabilityProbability
    $message=$_.message
    $component=$_.component
    $componentFilePath=($component -split ':')[1]
    $line=$_.line
    $issueStatus=$_.status
    $SHkey = $_.key
    $SHUrl="$sonarQubeUrl/hotspots/show?hotspot=$SHkey"
    $SHKeyResponse = Invoke-RestMethod -Uri $SHUrl -Headers $headers -Method Get
    $SHComment = $SHKeyResponse.comment.htmltext
    if ($SHComment -isnot [string]) {
        $SHComment = $SHComment[-1]
    }

    $toHashString="$rule$componentFilePath$line"
    $byteArray = [System.Text.Encoding]::UTF8.GetBytes($toHashString)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $hashBytes = $sha256.ComputeHash($byteArray)
    $hashString = [BitConverter]::ToString($hashBytes) -replace '-', ''

    $row = [PSCustomObject]@{
        Project = $project
        RuleKey = $rule
        RuleName = $ruleName
        Language = $ruleLang
        Probability = $probability
        Remediation = $message
        FilePath = $componentFilePath
        Line = $line
        Status = $issueStatus
        CompareKey = $hashString
        Comment = $SHComment
    }

    $row | Export-Csv -Path "$currentPath\$secHotspotCSVName" -NoTypeInformation -Append
}

Write-Host "Finish"

$ocusername = "<OKD_USERNAME>"
$ocpassword = Read-Host -Prompt "Enter your OKD password for $ocusername" -AsSecureString
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ocpassword)
$ocpassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)

$ocUrl = "https://api.example.com:6443"
$Registry = "registry.example.com"

oc login -u $ocusername -p $ocpassword $ocUrl --insecure-skip-tls-verify=true

if ($LASTEXITCODE -eq 0) {
    Write-Host "Successfully logged in to OKD cluster!" -ForegroundColor Green
    $ocToken = oc whoami -t
    Write-Host "Token retrieved successfully."
} else {
    Write-Error "Failed to log in to the cluster."
    exit 1
}

$targetimgtar = Read-Host "target image path"
$newName      = Read-Host "new image name"
$newTag       = Read-Host "new image tag"
$isNewImage = Read-Host "Is this a new image? (Type 'yes' or 'no')"
$Repobase = "<OPENSHIFT_PROJECT>"

$loadOutput = docker load -i $targetimgtar

if ($loadOutput -match "Loaded image(?: ID)?:\s*(.+)") {
    $originalImage = $matches[1]
    
    docker tag $originalImage "${newName}:${newTag}"
    Write-Host "Successfully tagged as -> ${newName}:${newTag}"
    
} else {
    Write-Warning "Could not parse the original image name from the output."
}

docker login -u $ocusername -p $ocToken $Registry

$localImage = "${newName}:${newTag}"
$remoteImage = "${Registry}/${Repobase}/${newName}:${newTag}"

docker tag $localImage $remoteImage

if ($isNewImage -eq 'yes') {
    Write-Host "Creating new OpenShift imagestream..." -ForegroundColor Cyan
    oc create imagestream $newName -n $Repobase
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SUCCESS: Imagestream created." -ForegroundColor Green
    } else {
        Write-Warning "Failed to create imagestream."
    }
} else {
    Write-Host "Skipping imagestream creation."
}

docker push $remoteImage

if ($LASTEXITCODE -eq 0) {
    Write-Host "SUCCESS: Image successfully pushed to $remoteImage" -ForegroundColor Green
} else {
    Write-Host "ERROR: Docker push failed! (Exit Code: $LASTEXITCODE)" -ForegroundColor Red
}

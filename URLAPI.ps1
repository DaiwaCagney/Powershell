param (
    [parameter(Mandatory = $true)]
    [string]$Url,
    [switch]$NoShorten,
    [switch]$NoQRCode,
    [switch]$Show,
    [int]$Size = 150
)

$envVarName = "ReurlApiKey"
$apiKey = [Environment]::GetEnvironmentVariable($envVarName, "User")

function CallRecurlApi($url, $apiKey) {
    $jsonBody = @{ url = $url } | ConvertTo-Json
    $headers = @{ 'reurl-api-key' = $apiKey }
    $res = Invoke-RestMethod -Method Post -Uri "https://api.reurl.cc/shorten" -Body $jsonBody -Headers $headers -ContentType "application/json"
    if ($res.res -ne "success") { throw ($res.code + ' ' + $res.msg) }
    return $res.short_url
}

function ShortenUrl($url) {
    if ([string]::IsNullOrEmpty($apiKey)) {
        $reurlDevUrl = "https://reurl.cc/dev/main/tw"
        Write-Host "Get API Key from $reurlDevUrl"
        Start-Process $reurlDevUrl
        while ($true) {
            $apiKey = Read-Host "Enter apikey: "
            if ([string]::IsNullOrEmpty($apiKey)) {
                Write-Host "Empty" -ForegroundColor Red
            }
            else {
                try {
                    $shortenUrl = CallRecurlApi $url $apiKey
                    [Environment]::SetEnvironmentVariable($envVarName, $apiKey, "User")
                    return $shortenUrl
                }
                catch {
                    Write-Host $_ -ForegroundColor Red
                }
            }
        }    
    }
    else {
        return CallRecurlApi $url $apiKey
    }
}

function GenerateQRCode($text) {
    $qrCodeUrl = "https://quickchart.io/qr?text=$([Uri]::EscapeDataString($text))&size=$Size"
    $tempFile = [IO.Path]::GetTempFileName() + ".png"
    Invoke-WebRequest -Uri $qrCodeUrl -OutFile $tempFile
    Add-Type -AssemblyName System.Windows.Forms
    $image = [System.Drawing.Image]::FromFile($tempFile)
    [System.Windows.Forms.Clipboard]::SetImage($image)    
    Write-Host "QR Code copied"
    if ($Show) { Start-Process $tempFile }
}

if (!$NoShorten) {
    $shortUrl = ShortenUrl $Url $apiKey
}
else {
    $shortUrl = $Url
}
if ($NoQRCode) {
    Set-Clipboard -Value $shortUrl
    Write-Host "$shortUrl"
}
else {
    Write-Host "$shortUrl"
    GenerateQRCode $shortUrl   
}
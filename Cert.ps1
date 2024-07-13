param (
    [string]$hostNport
)

if (!$hostNport) {$hostNport="www.google.com"}
if (!$hostNport.Contains(":")) {
    $hostNport+=":443"
}

$process=New-Object System.Diagnostics.Process

$process.StartInfo.FileName="openssl.exe"
$process.StartInfo.Arguments="s_client -showcerts -connect $hostNport"
$process.StartInfo.UseShellExecute=$false
$process.StartInfo.RedirectStandardOutput=$true
$process.StartInfo.RedirectStandardInput=$true
$process.StartInfo.RedirectStandardError=$true

$process.Start() | Out-Null
$process.StandardInput.WriteLine("Q")

$output=$process.StandardOutput.ReadToEnd();
$process.WaitForExit();

$CN={param($s)
    $m=[Regex]::Match($s,'^CN=[^,]+')
    if (!$m.Success) {return $s}
    return "$([char]0x1b)[32m"+$m.Value+"$([char]0x1b)[0m"+$s.Substring($m.Value.Length)
}

foreach ($certB64 in [Regex]::Matches($output, "(?ims)-----BEGIN CERTIFICATE-----(?<c>.+?)-----END CERTIFICATE-----")) {
    $pem=$certB64.Groups["c"].Value.Replace("`r","").Replace("`n","")
    $cert=[System.Security.Cryptography.X509Certificates.X509Certificate2]::new([System.Convert]::FromBase64String($pem))
    Write-Host "$([char]0x1b)[32m$([char]0x1b)[0m".PadRight(64,"=")
    Write-Host "To: $($CN.Invoke($cert.Subject))"
    Write-Host "Issuer: $($CN.Invoke($cert.Issuer))"
    Write-Host "Effective: $([char]0x1b)[32m$($cert.NotBefore.ToString("yyyy-MM-dd HH:mm:ss"))$([char]0x1b)[0m To $([char]0x1b)[32m$($cert.NotAfter.ToString("yyyy-MM-dd HH:mm:ss"))$([char]0x1b)[0m"
    Write-Host "Thumbprint: $([char]0x1b)[32m$($cert.Thumbprint)$([char]0x1b)[0m"
    Write-Host ""
}
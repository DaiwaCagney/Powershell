param (
    [Parameter(Mandatory=$true)]
    [string]$Subnet,
    [Parameter(Mandatory=$true)]
    [string]$Filename
)

function Get-IpRange {
    param (
        [string]$Subnet
    )

    $subnetParts = $Subnet.Split('/')
    $ipAddress = $subnetParts[0]
    $prefixLength = [int]$subnetParts[1]

    $ipBytes = [System.Net.IPAddress]::Parse($ipAddress).GetAddressBytes()

    [Array]::Reverse($ipBytes)

    $ipInt = [BitConverter]::ToUInt32($ipBytes, 0)

    $hostBits = 32 - $prefixLength

    $numberOfHosts = [math]::Pow(2, $hostBits) - 1

    $startIp = $ipInt

    $endIp = $ipInt + $numberOfHosts

    $ipRange = @()

    for ($i = $startIp; $i -le $endIp; $i++) {
        $ipBytes = [BitConverter]::GetBytes($i)
        [Array]::Reverse($ipBytes)
        $ipRange += [System.Net.IPAddress]::new($ipBytes)
    }

    return $ipRange
}

$ipRange = Get-IpRange -Subnet $Subnet

foreach ($ip in $ipRange) {
    $ip.ToString() | Out-File -FilePath $Filename -Append
}

Write-Host "Output to $Filename"
function Convert-IpToInt {
    param (
        [string]$IpAddress
    )

    $octets = $IpAddress.Split('.')
    return ([int]$octets[0] -shl 24) -bor ([int]$octets[1] -shl 16) -bor ([int]$octets[2] -shl 8) -bor ([int]$octets[3])
} 

function Convert-CidrToMask {
    param (
        [int]$PrefixLength
    )

    $mask = 0

    for ($i = 0; $i -lt $PrefixLength; $i++) {
        $mask = $mask -shl 1 -bor 1
    }

    $mask = $mask -shl (32 - $PrefixLength)

    return $mask
}

function Test-IpInSubnet {
    param (
        [Parameter(Mandatory = $true)]
        [string]$IpAddress,
        [Parameter(Mandatory = $true)]
        [string]$Subnet
    )

    $subnetParts = $Subnet.Split('/')
    $networkAddress = $subnetParts[0]
    $prefixLength = [int]$subnetParts[1]

    $ipInt = Convert-IpToInt -IpAddress $IpAddress
    $networkInt = Convert-IpToInt -IpAddress $networkAddress
    $maskInt = Convert-CidrToMask -PrefixLength $prefixLength

    $ipNetworkInt = $ipInt -band $maskInt
    $subnetInt = $networkInt -band $maskInt

    if ($ipNetworkInt -eq $subnetInt) {
        return $true
    } else {
        return $false
    }
}

$ipAddress = Read-Host "Input the IP Address"
$subnet = Read-Host "Input the Subnet"

if (Test-IpInSubnet -IpAddress $ipAddress -Subnet $subnet) {
    Write-Output "$ipAddress is within the subnet $subnet"
} else {
    Write-Output "$ipAddress is NOT within the subnet $subnet"
}
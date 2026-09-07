$UserList = Get-Content UsernameList.txt

$filteredUsers = @()
$activeUsersList = @()

Write-Host "User List"

foreach ($user in $UserList) {
    Write-Host "$user"
}

Write-Host ""

foreach ($user in $UserList) {
    $user = $user.Trim().ToLower()
    if ([string]::IsNullOrWhiteSpace($user)) { continue }

    if ($user -notmatch "@") {
        $filteredUsers += $user
    }
    elseif ($user -match "(?i)^(.+)@gmail\.com$") {
        $filteredUsers += $matches[1]
    }
    elseif ($user -match "(?i)^(.+)@hotmail\.com$") {
        $filteredUsers += $matches[1]
    }
    else {
        Write-Host "Filtered out (ignored domain): $user"
    }
}

$filteredUsers = $filteredUsers | Sort-Object -Unique

Write-Host ""
Write-Host "Filtered User List"

foreach ($user in $filteredUsers) {
    Write-Host "$user"
}

Write-Host ""

foreach ($user in $filteredUsers) {
    $netUserOutput = net user $user /domain 2>&1

    if ($LASTEXITCODE -eq 0) {
        $fullName = ""
        $isActive = ""

        foreach ($line in $netUserOutput) {
            if ($line -match "^Full Name\s+(.*)$") {
                $fullName = $matches[1].Trim()
            }
            if ($line -match "^Account active\s+(.*)$") {
                $isActive = $matches[1].Trim()
            }
        }
        if ($isActive -eq "Yes") {
            Write-Host "Active - $user ($fullName)" -ForegroundColor Green
            
            if ($user -match "\d{10}") {
                $user = "$user@gmail.com"
            }

            $activeUsersList += [PSCustomObject]@{
                'Fullname' = $fullName
                'Username' = $user
            }
        } else {
            Write-Host "Disabled - $user" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "Not Found - $user" -ForegroundColor Red
    }
}

if ($activeUsersList.Count -gt 0) {
    $activeUsersList | Export-Csv -Path "ExistNameList.csv" -NoTypeInformation -Encoding UTF8
    Write-Host "Export complete! Saved to ExistNameList.csv" -ForegroundColor Cyan
} else {
    Write-Host "No active users were found to export." -ForegroundColor Yellow
}

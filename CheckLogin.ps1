Param (
    [string]$Right,
    [switch]$Expand
)
$ErrorActionPreference='STOP'
function ListRights($right,$expand) {
    $TempPath = [System.IO.Path]::GetTempFileName()
    SecEdit.exe /export /cfg $TempPath | Out-Null
    $raw = Get-Content $TempPath
    Remove-Item $TempPath
    $rights=@{}
    $inZone=$false
    $raw | ForEach-Object {
        if($inZone) {
            if($_ -match '^\s*(\S+)\s*=\s*(\S+)\s*$') {
                $RightName=$matches[1]
                $rights[$RightName]=@()
                $matches[2].Split(',') | ForEach-Object {
                    try {
                        $name=$_
                        if ($name -match '^\*') {
                            $sid = New-Object System.Security.Principal.SecurityIdentifier($name.Trim('*'))
                            $name = $sid.Translate([System.Security.Principal.NTAccount]).Value
                        }
                    }
                    catch {
                    }
                    $rights[$RightName]+=$name
                }
            }
            elseif ($_ -match '\[]') {
                $inZone=$false
            }
        }
        elseif ($_ -eq '[Privilege Rights]') {
            $inZone=$true
        }
    }
    if ($right) {
        Write-Host $right
        Write-Host ('-' * 60)
        if ($expand) {
            $localGroupMembers=@{}
            Get-LocalGroup | ForEach-Object {
                $sid = New-Object System.Security.Principal.SecurityIdentifier($_.Sid)
                $account = $sid.Translate([System.Security.Principal.NTAccount]).Value
                $localGroupMembers[$account] = Get-LocalGroupMember $_ | Select-Object -ExpandProperty Name
            }
            $rights[$right] | ForEach-Object {
                Write-Host $_
                $groupName = $_
                if ($localGroupMembers.ContainsKey($groupName)) {
                    $localGroupMembers[$groupName] | ForEach-Object {
                        Write-Host " - $_"
                    }
                }
                else {
                    Write-Host " (No One)"
                }
            }
        }
        else {
            $rights[$right]
        }
    }
    else {
        $rights
    }
}
$checkadmin = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-Not $checkadmin.IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Not Administrator" -ForegroundColor Red
}
else {
    ListRights $Right $Expand
}
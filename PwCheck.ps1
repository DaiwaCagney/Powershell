$ProgressPreference='SilentlyContinue'

while($true) {
    $pw=Read-Host "Enter Password" -AsSecureString
    if ($pw.Length -eq 0) {
        Write-Host "Finish"
        break
    }
    $ptr=[System.Runtime.InteropServices.Marshal]::SecureStringToGlobalAllocUnicode($pw)
    $passwd=[System.Runtime.InteropServices.Marshal]::PtrToStringUni($ptr)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeGlobalAllocUnicode($ptr)
    $pwBytes=[System.Text.Encoding]::UTF8.GetBytes($passwd)
    $hash=[System.BitConverter]::ToString([System.Security.Cryptography.SHA1]::Create().ComputeHash($pwBytes)).Replace('-','')
    $prefix=$hash.Substring(0,5)
    $remain=$hash.Substring(5)
    Write-Host "$prefix - $remain" -ForegroundColor Green
    $result=(Invoke-WebRequest "https://api.pwnedpasswords.com/range/$prefix").Content.Split("`n") | Select-String -Pattern $remain -CaseSensitive
    if ($result) {
        $p=$result -split ':'
        Write-Host "Existed in HIBP " -ForegroundColor Yellow -NoNewline
        Write-Host (+$p[1]).ToString('n0') -ForegroundColor Red -NoNewline
        Write-Host " times" -ForegroundColor Yellow
        Write-Host $result -ForegroundColor Cyan
    }
}
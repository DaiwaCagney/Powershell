#Create an encrypted text
$chiper = Read-Host -AsSecureString "Please input some text"
Write-Host "The Type of the encrypted text is " $chiper.GetType().fullname

#Show the encrypted text
$showchiper = ConvertFrom-SecureString -SecureString $chiper
Write-Host "The encrypted text can be shown as:"
Write-Host $showchiper

#Convert again
$chiper2 = ConvertTo-SecureString -String $showchiper

#Decryption
$method = Read-Host "Choose a method to decrypt: (1) Marshal (2) PSCredential"
if ($method -eq "1") {
    Write-Host "Using Marshal"
    $Marshal = [System.Runtime.InteropServices.Marshal]
    $Bstr = $Marshal::SecureStringToBSTR($chiper2)
    $plaintext = $Marshal::PtrToStringAuto($Bstr)
    $Marshal::ZeroFreeBSTR($Bstr)
    Write-Host $plaintext
} elseif ($method -eq "2") {
    Write-Host "Using PSCredential"
    $credential = New-Object System.Management.Automation.PSCredential('username',$chiper2)
    $plaintext2 = $credential.GetNetworkCredential().Password
    Write-Host $plaintext2
} else {
    Write-Host "Please input 1 or 2"
    exit
}

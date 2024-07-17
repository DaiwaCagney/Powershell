$pw=Read-Host "Please input word"
$charpool=0
$setName=@()
if ($pw -match '[0-9]') {$charpool+=10; $setName+='Number'}
if ($pw -cmatch '[a-z]') {$charpool+=26; $setName+='LowerCase'}
if ($pw -cmatch '[A-Z]') {$charpool+=26; $setName+='UpperCase'}
if ($pw -cmatch '[^0-9a-zA-z]') {$charpool+=32;$setName+='SpecChar'}
$length=$pw.Length
$count=[bigint]::Pow($charpool,$length).ToString('n0')
Write-Host "Length: $length Contain: ($($setName -join '/')) Combination: $count"
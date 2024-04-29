$esc = [char]27
$color = ("Black","Red","Green","Yellow","Blue","Magenta","Cyan","White")

#Use Case
for (($i=30); ($i -le 37); ($i++)) {
    $j=$i+60
    $k=$i+10
    $l=$i+70
    $message1 = $esc+"["+$i+"m"+$color[$i-30]+$esc+"[0m"+" "
    $message2 = $esc+"["+$j+"m"+$color[$i-30]+$esc+"[0m"+" "
    $message3 = $esc+"["+$k+"m"+$color[$i-30]+$esc+"[0m"+" "
    $message4 = $esc+"["+$l+"m"+$color[$i-30]+$esc+"[0m"+" "
    $message5 = $esc+"["+$i+";1m"+$color[$i-30]+$esc+"[0m"+" "
    $message6 = $esc+"["+$i+";3m"+$color[$i-30]+$esc+"[0m"+" "
    $message7 = $esc+"["+$i+";4m"+$color[$i-30]+$esc+"[0m"+" "
    $message=$message1+$message2+$message3+$message4+$message5+$message6+$message7
    Write-Host $message
}

#Sampling
for (($i=30);($i -le 37);($i++)) {
    $k=$i+60
    $message = ""
    for (($j=40);($j -le 47);($j++)) {
        $l=$j+60
        $message=$message+$esc+"["+$i+"m"+$esc+"["+$j+"m"+" A "+$esc+"[0m"
        $message=$message+$esc+"["+$i+"m"+$esc+"["+$l+"m"+" A "+$esc+"[0m"
        $message=$message+$esc+"["+$k+"m"+$esc+"["+$j+"m"+" A "+$esc+"[0m"
        $message=$message+$esc+"["+$k+"m"+$esc+"["+$l+"m"+" A "+$esc+"[0m"
    }
    Write-Host $message
}
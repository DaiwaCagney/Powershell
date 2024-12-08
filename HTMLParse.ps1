$URL = Read-Host "Enter URL"
$resp = Invoke-WebRequest -Uri $URL
$doc = $resp.ParsedHtml.documentElement.ownerDocument
$doc.title

$doc.all | Where-Object { $_.tagName -eq $tag -and $_.getAttribute($attribute) -match $AttrValue } |
Select-Object -First 3 | ForEach-Object {
    $link = $_.getElementsByTagName('a')[0]
    "[{0}]({1})" -f $link.innerText, $link.href
}
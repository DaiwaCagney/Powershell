function ReadingFile {
    param(
        [Parameter(Mandatory = $true)][string]$FileName
    )

    $FilePro = @{
        Encoding = 'Not UTF-8 or Unicode'
        Content = ''
    }

    $char = [char]0xFFFD

    $Bytes = [System.IO.File]::ReadAllBytes($FileName)
    $FilePro.Content = [BitConverter]::ToString($bytes)

    $UTF8Test = [System.Text.Encoding]::UTF8.GetString($Bytes)
    if (!$UTF8Test.Contains($char)) {
        $FilePro.Encoding = 'UTF-8'
        $FilePro.Content = $UTF8Test
        return $FilePro
    }

    $UnicodeTest = [System.Text.Encoding]::Unicode.GetString($Bytes)
    if (!$UnicodeTest.Contains($char)) {
        $FilePro.Encoding = 'Unicode'
        $FilePro.Content = $UnicodeTest
        return $FilePro
    }

    return $FilePro
}

$FileName = Read-Host "Please tell me where is the file"
$Result = ReadingFile -FileName $FileName
Write-Host "File: $FileName, Encoding: $($Result.Encoding)" -ForegroundColor Blue
Write-Host "$($Result.Content)" -ForegroundColor Green
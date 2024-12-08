Get-Content .\ComputerList.txt | ForEach-Object {
    Get-ADComputer -Identity "$_" | Select-Object DistinguishedName >> ADPathResult.txt
}
$taskParams = @(
    "/Create",
    "/TN", "`"$taskPath\$taskName`"",
    "/SC", "monthly",
    "/D", "1", #Which day in month
    "/ST", "01:00", #Start time
    "/TR", "`"powershell.exe -NoProfile -ExecutionPolicy ByPass -NonInteractive -WindowStyle Hidden -Command '$Path_To_Script $parameter1'`"", 
    "/RU", "System"
)
schtasks.exe $taskParams
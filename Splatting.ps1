# Define paramaters of a command before calling the command - Hastable prefixed with @symbol
$getProcess = @{
    Name = 'explorer'
}

Get-Process @getProcess


# Longer example to add a Scheduled Task at Midnight
$newTaskAction = @{
    Execute = 'pwsh.exe'
    Argument = 'Write-Host "Hello World"'
}

$newDailyTrigger =@{
    Daily = $true;
    At = '00:00:00'
}

$registerTask = @{
    TaskName    = 'TaskName'
    Action      = New-ScheduledTaskAction @newTaskAction
    Trigger     = New-ScheduledTaskTrigger @newDailyTrigger
    RunLevel    = 'Limited'
    Description = 'Splatting is easy to read'
}
# I don't actually want to do this though :p
# Register-ScheduledTask @registerTask

"Hello World" | Out-File oldname.txt
# Positional Splatting
# Done by using an array
$renameItem = 'oldname.txt', 'newname.txt'
Rename-Item @renameItem
Remove-Item $renameItem[1]
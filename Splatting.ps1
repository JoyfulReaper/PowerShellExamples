# Define paramaters of a command before calling the command
$getProcess = @{
    Name = 'explorer'
}

Get-Process @getProcess
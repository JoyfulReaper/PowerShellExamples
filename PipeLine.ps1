#Pipeline - Output of Get-Process sent to input of Where-Object
Get-Process | Where-Object WorkingSet -gt 50mb

#Accessing Properties
$process = Get-Process -Id $PID
$process.Name

#Properties of an object as also objects
$process.StartTime.DayOfWeek
# CreateOutOfProcessRunspace Example
#
# Kyle Givler
# https://github.com/JoyfulReaper/PowerShellExamples

# Disclaimer: Still learning the basics of Powershell, but had a need for this and was struggling to find good examples
#
# Suggestions / Bug Fixes/ Improvement / (un)helpful critism Welcome!
#
# I will Continue to improve this as I can, and as I learn PowerShell Better
# I am aware of PoshRSJob...

#########################################################################################################################

function Invoke-Function
{
    param([String]$number)

    Start-Sleep -Seconds (Get-Random -Maximum 10)
    return "I'm number $number"
}

#########################################################################################################################

$jobs = New-Object Collections.Generic.List[PSCustomObject]

$function = Get-Command Invoke-Function
$functionEntry = [System.Management.Automation.Runspaces.SessionStateFunctionEntry]::new(
    $function.Name,
    $function.Definition
)

$initialSessionState = [initialsessionstate]::CreateDefault2()
$initialSessionState.Commands.Add($functionEntry)

$runspace = [RunspaceFactory]::CreateOutOfProcessRunspace($null)
$runspace.Open()

try {
    for($i = 0; $i -lt 30; $i++)
    {
        $instance = [PowerShell]::Create($initialSessionState)
        [void]$instance.AddCommand("Invoke-Function").AddParameter('number', $i)

        $job = [PSCustomObject]@{
            Id          = $instance.InstanceId
            Instance    = $instance
            AsyncResult = $instance.BeginInvoke()
        } | Add-Member State -MemberType ScriptProperty -PassThru -Value {
            $this.Instance.InvocationStateInfo.State
        }
        $jobs.Add($job)
    }


    while($jobs.Count -gt 0)
    {
        $completed = $jobs | Where-Object {$_.State -eq 'Completed'}
        $running = $jobs | Where-Object {$_.State -eq 'Running'}
        $running = $running.count
        foreach($complete in $completed)
        {
            [void]$jobs.Remove($complete)
            $result = $complete.Instance.EndInvoke($complete.AsyncResult)
            Write-Output $result
            $complete.Instance.Dispose()
        }

        $remaining = $jobs.Count
        Write-Output "Jobs Remaining $remaining"
        Write-Output "Jobs Running $running"
        Start-Sleep -Seconds 2
    }
} finally {
    $running = $jobs | Where-Object {$_.State -eq 'Running'}
    foreach($run in $running)
    {
        $run.Stop()
    }
    if($jobs.Count -ne 0)
    {
        foreach($job in $jobs)
        {
            $job.Instance.Dispose()
        }
    }

    $runspace.Close()
    $runspace.Dispose()
}
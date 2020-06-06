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
#
# This is a test of CreateOutOfProcessRunspace I kow some of the code isn't the best :(
# Pull request welcome :)
#

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

$totalJobs = 40
$completeJobs = 0
$maxThreads = 5
$startedJobs = 0;
$count = 0;

try {
    while($completeJobs -le $totalJobs)
    {
        $running = $jobs | Where-Object {$_.State -eq 'Running'}
        $running = $running.count
        if($running -le $maxThreads -And $startedJobs -le $totalJobs)
        {
            echo "Adding more. Running: $running Complete: $completeJobs Started: $startedJobs"
            $instance = [PowerShell]::Create($initialSessionState)
            [void]$instance.AddCommand("Invoke-Function").AddParameter('number', $count)

            $job = [PSCustomObject]@{
                Id          = $instance.InstanceId
                Instance    = $instance
                AsyncResult = $instance.BeginInvoke()
            } | Add-Member State -MemberType ScriptProperty -PassThru -Value {
                $this.Instance.InvocationStateInfo.State
            }
            $jobs.Add($job)
            $count++
            $startedJobs++
        }
        $completed = $jobs | Where-Object {$_.State -eq 'Completed'}
        foreach($complete in $completed)
        {
            [void]$jobs.Remove($complete)
            $result = $complete.Instance.EndInvoke($complete.AsyncResult)
            Write-Output $result
            $complete.Instance.Dispose()
            $completeJobs++
        }
    }
} finally {
    Start-Sleep -Seconds 2
    $running = $jobs | Where-Object {$_.State -eq 'Running'}
    foreach($run in $running)
    {
        $run.instance.Stop()
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
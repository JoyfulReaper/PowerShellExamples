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
# This is a test / example of CreateOutOfProcessRunspace
#

#########################################################################################################################

$script = {
    param([String]$number)

    Start-Sleep -Seconds (Get-Random -Maximum 30)
    return "I'm number $number"
}

#########################################################################################################################

$jobs = New-Object Collections.Generic.List[PSCustomObject]

$totalJobs = 100
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
            echo "Adding more. Running: $running MaxThreads: $maxThreads Complete: $completeJobs Started: $startedJobs"

            $runspace = [RunspaceFactory]::CreateOutOfProcessRunspace($null)
            $runspace.Open()
            $instance = [PowerShell]::Create()
            $instance.Runspace = $runspace

            #$script = Get-Content -Path .\testS.ps1
            [void]$instance.AddScript($script).AddArgument($count)

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
             Write-Output $instance.Streams.Error
             $complete.Instance.Dispose()
             $completeJobs++
         }
    }
} finally {
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
}
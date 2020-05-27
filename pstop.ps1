<#
.Synopsis
    

.DESCRIPTION
    Author  : D3athByMonkey
    Created : 5/27/2020
    Version : 1.0
    Process : 1. Execute .\pstop.ps1 and watch as the data warms your heart of course.

    Revision:


.EXMAPLE
    .\pstop.ps1
    
    Description
    -----------
    Collections statistics on CPU/Mem/Process disk impact and shows the top 10 CPU/Mem impacting processes.

.EXMAPLE
    .\pstop.ps1 -sampleInterval 5
    
    Description
    -----------
    Samples over 5 seconds. HOWEVER right now its not going to show min/max output.

.INPUTS
    System.String
.OUTPUTS
    System.Object
.NOTES
    Future versions will break out the functions to be more modular.
.Functionality
    Guided performance troubleshooting in powershell
#>

param
(
    [Parameter(ParameterSetName="SampleInterval", Mandatory=$false)]
    [int]$sampleInternval = 1
            
)
$ErrorActionPreference = "SilentlyContinue"
#Feed in metric paths and parse out the instance, creating and formatting the output into a collection 
Function Get-ProcessImpact($Path, $Process)
{
    ##Let's get some of the core parts we want. Split the path to get the processes instance
    $node = $Path.Split("")
    $processInstance = $Path.Split("(*)")[1]

   
                            #Create the variables to use for the value query.
                            $nodeName = "\\" + $Path.Split("\")[2]
                            $cpu = "\process($ProcessInstance)\% processor time"
                            $threads = "\Process($ProcessInstance)\Thread Count"
                            $handles =  "\Process($ProcessInstance)\Handle Count"
                            $workingSet = "\Process($ProcessInstance)\Working Set - Private"
                            $readOps = "\Process($ProcessInstance)\IO Read Operations/sec"
                            $writeOps =  "\Process($ProcessInstance)\IO Write Operations/sec"
                            $readBytes = "\Process($ProcessInstance)\IO Read Bytes/sec"
                            $writeBytes = "\Process($ProcessInstance)\IO Write Bytes/sec"

                            $outPutInfo = New-Object System.Object
                            $outPutInfo | Add-Member -Type NoteProperty -Name "Process Name" -Value $processInstance
                            $outPutInfo | Add-Member -Type NoteProperty -Name "CPU % Total" -Value ([int32](($counters | ?{$_.Path -eq $nodeName+$cpu}).CookedValue / $totalProcessors))
                            $outPutInfo | Add-Member -Type NoteProperty -Name "CPU %/Proc" -Value ([int32]($counters | ?{$_.Path -eq $nodeName+$cpu}).CookedValue)
                            $outPutInfo | Add-Member -Type NoteProperty -Name "Threads" -Value ([int32]($counters | ?{$_.Path -eq $nodeName+$threads}).CookedValue)
                            $outPutInfo | Add-Member -Type NoteProperty -Name "Handles" -Value  ([int32]($counters | ?{$_.Path -eq $nodeName+$handles}).CookedValue)
                            $outPutInfo | Add-Member -Type NoteProperty -Name "Memory MB" -Value ([int32](($counters | ?{$_.Path -eq $nodeName+$workingSet}).CookedValue / 1024 / 1024))
                            $outPutInfo | Add-Member -Type NoteProperty -Name "Read IO/s" -Value  ([int32]($counters | ?{$_.Path -eq $nodeName+$readOps}).CookedValue)
                            $outPutInfo | Add-Member -Type NoteProperty -Name "Write IO/s" -Value ([int32]($counters | ?{$_.Path -eq $nodeName+$writeOps}).CookedValue)
                            $outPutInfo | Add-Member -Type NoteProperty -Name "Read Bytes/s" -Value ([int32]($counters | ?{$_.Path -eq $nodeName+$readBytes}).CookedValue)
                            $outPutInfo | Add-Member -Type NoteProperty -Name "Write Bytes/s" -Value ([int32]($counters | ?{$_.Path -eq $nodeName+$writeBytes}).CookedValue)

                            return $outPutInfo
            
}

#The TOP level information.
Function Write-BaseMetrics
{
        Write-Host ("Last Boot:`t{0}`tProcesses:`t{1}`tThreads:`t{2}`tHandles:`t{3}`tLogical Processors: {4}" -f $upTime, $totalProcesses, $totalThreads, $totalHandles, $totalProcessors)
        Write-Host "--------------------------------------------------------------------------------------------------------------------------------------"
        Write-Host ("% Processor Time:`t{0}`tAvailable/Total MBytes:`t{1}/{2}`tDisk Reads/sec:`t{3}`tDisk Writes/sec`t{4}`n" -f [int32]($counters | ?{$_.Path -like "*processor(_total)\% processor time*"}).CookedValue,
        [int32]($counters | ?{$_.Path -like "*Memory\Available MBytes*"}).CookedValue,   
        $totalMemory,
        [int32]($counters | ?{$_.Path -like "*Memory\Available MBytes*"}).CookedValue, 
        [int32]($counters | ?{$_.Path -like "*\LogicalDisk(c:)\Disk Reads/sec*"}).CookedValue, 
        [int32]($counters | ?{$_.Path -like "*\LogicalDisk(c:)\Disk Writes/sec*"}).CookedValue)

        #We want FOUR per line. So lets decide how many we have then do some math.

        if (($counters | ?{$_.Path -like "*processor(*"}).Count-1 -lt 4)
        {
            for ($num=0; $num -le ($counters | ?{$_.Path -like "*processor(*" -and $_.Path -notlike "*_total*"}).Count-1;$num++)
            {            
                Write-Host ("Processor {0}: {1}`t" -f ($counters | ?{$_.Path -like "*processor(*"})[$num].Path.Split("(*)")[1], [int32]($counters | ?{$_.Path -like "*processor(*"}).CookedValue[$num]) -nonewline
            }
        }
        else
        {
            #This is messy but it does work. Calculate the amount of iterations needed per the amount of procs to display 4 proc data per line.
            $iterations = [int32](($counters | ?{$_.Path -like "*processor(*"}).Count-1)/4
            [System.Collections.ArrayList]$procCollection = @()
            ($counters | ?{$_.Path -like "*processor(*" -and $_.Path -notlike "*_total*"}) | %{$procCollection.Add($_)} | Out-Null

            #Main iterations
            for($iteration=0; $iteration -lt $iterations;$iteration++)
            {
                
                #4 count per line
                for ($line=0; $line -lt 4;$line++)
                {
                    Write-Host ("Processor {0}: {1}`t" -f ($procCollection | ?{$_.Path -like "*processor(*"})[0].Path.Split("(*)")[1], [int32]($procCollection | ?{$_.Path -like "*processor(*"}).CookedValue[0]) -nonewline
                    $procCollection.RemoveAt(0)
                    
                }
                Write-Host ""
            }

        }

        write-host ""
}

    $upTime = (Get-CimInstance -ClassName win32_operatingsystem).lastbootuptime
    $totalMemory = (Get-WmiObject Win32_PhysicalMemory | measure-object Capacity -sum).sum/1mb
    [System.Collections.ArrayList]$collection = @()
    [System.Collections.ArrayList]$memCollection = @()
    Write-Host ("Sample interval has been set to {0}" -f $sampleInternval)
    while ($1 -ne 5)
    {
        $totalProcesses = (Get-Process).Count
        $totalThreads = (Get-Process).Threads.Count
        $totalHandles = (Get-Process).Handles.Count
        #Counter Queries
        $counters = ((Get-Counter -Counter "\Processor(*)\% Processor Time", 
        "\Memory\Available MBytes", 
        "\LogicalDisk(c:)\Disk Reads/sec", 
        "\LogicalDisk(c:)\Disk Writes/sec",
        "\Process(*)\% Processor Time",
        "\Process(*)\Thread Count", 
        "\Process(*)\Handle Count", 
        "\Process(*)\Working Set - Private", 
        "\Process(*)\IO Read Operations/sec", 
        "\Process(*)\IO Write Operations/sec",
        "\Process(*)\IO Read Bytes/sec",  
        "\Process(*)\IO Write Bytes/sec" -SampleInterval $sampleInternval -ErrorAction SilentlyContinue).CounterSamples | Group-Object InstanceName).Group
        $totalProcessors = ($counters | ?{$_.Path -like "*processor(*"}).Count-1

        $topProcessor = $counters | ?{$_.Path -like "*% processor time*" -and $_.Path -notlike "*processor(*" -and $_.Path -notlike "*process(_total*" -and $_.Path -notlike "*process(idle*"} | sort CookedValue -desc | select -First 10
        $topMem = $counters | ?{$_.Path -like "*working*" -and $_.InstanceName -ne "idle" -and $_.InstanceName -notlike "*_total*" -and $_.InstanceName -ne "memory compression" -and $_.CookedValue -gt 0} | sort CookedValue -desc | select -First 10
    
        $collection.Clear()
        if ($topProcessor.Path.Count -gt 1)
        {
            for($num=0; $num -le $topProcessor.Path.Count-1;$num++)
            {
                $output = Get-ProcessImpact -Path $topProcessor.Path[$num] -Process $topProcessor.InstanceName[$num]
                $collection.Add($output) | Out-Null
            }
        }else
        {
             foreach ($instance in $topProcessor.Path)
            {
               $output = Get-ProcessImpact -Path $topProcessor.Path -Process $topProcessor.Path
               $collection.Add($output) | Out-Null
            }
        }
        $Memcollection.Clear()
    if ($topMem.InstanceName.Count -gt 1)
        {
            
             for($num=0; $num -le $topMem.InstanceName.Count-1;$num++)
            {
                $memCollection.Add((Get-ProcessImpact -Path $topMem.Path[$num] -Process $topMem.InstanceName[$num])) | Out-Null
            }
        }else
        {
             foreach ($instance in $topMem.InstanceName)
            {
      
              $memCollection.Add((Get-ProcessImpact -Path $topMem.Path -Process $topMem.Path)) | Out-Null
            }
        }

        cls
        Write-BaseMetrics
        Write-Host -ForegroundColor Yellow "Highest CPU Consumers"
        $collection | sort "CPU % Total" -desc | ft -a
        Write-Host -ForegroundColor Yellow "Hungry Memory Hippos"
        $memCollection | sort "Memory MB" -desc | ft -a
    }
        

<#
.Synopsis
    

.DESCRIPTION
    Author  : D3athByMonkey
    Created : 5/27/2020
    Version : 1.0
    Process : 1. Execute .\psiostat.ps1 and watch as the data warms your heart of course.

    Revision:


.EXMAPLE
    .\psiostat.ps1
    
    Description
    -----------
    Collects statistics on Disk IO

.EXMAPLE
    .\psiostat.ps1 -sampleInterval 5
    
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
Function Get-DiskPerf($Path)
{
    $nodeName = "\\" + $counters[0].Path.Split("\")[2]

    $diskTime = "\logicaldisk($path)\% disk time"
    $diskQueue = "\LogicalDisk($path)\Current Disk Queue Length"
    $diskReadQueue = "\LogicalDisk($path)\Avg. Disk Read Queue Length"
    $diskWriteQueue = "\LogicalDisk($path)\Avg. Disk Write Queue Length"
    $diskTransfers = "\LogicalDisk($path)\Avg. Disk sec/Transfer"
    $diskReads = "\LogicalDisk($path)\Disk Reads/sec"
    $diskWrites = "\LogicalDisk($path)\Disk Writes/sec"
    $diskReadB = "\LogicalDisk($path)\Disk Read Bytes/sec"
    $diskWriteB = "\logicaldisk($path)\disk write bytes/sec"
    $diskIdle = "\LogicalDisk($path)\% Idle Time"

    $outPutInfo = New-Object System.Object
    $outPutInfo | Add-Member -Type NoteProperty -Name "Disk" -Value $path
    $outPutInfo | Add-Member -Type NoteProperty -Name "% Time" -Value ([Math]::Round(($counters | ?{$_.Path -eq $nodeName+$diskTime}).CookedValue,2))
    $outPutInfo | Add-Member -Type NoteProperty -Name "Reads/sec" -Value ([Math]::Round(([int32]($counters | ?{$_.Path -eq $nodeName+$diskReads}).CookedValue),2))
    $outPutInfo | Add-Member -Type NoteProperty -Name "Writes/sec" -Value  ([Math]::Round(([int32]($counters | ?{$_.Path -eq $nodeName+$diskWrites}).CookedValue),2))
    $outPutInfo | Add-Member -Type NoteProperty -Name "Read KiloBytes/sec" -Value ([Math]::Round(([int32]($counters | ?{$_.Path -eq $nodeName+$diskReadB}).CookedValue / 1024),2))
    $outPutInfo | Add-Member -Type NoteProperty -Name "Write KiloBytes/sec" -Value ([Math]::Round(([int32]($counters | ?{$_.Path -eq $nodeName+$diskWriteB}).CookedValue / 1024), 2))
    $outPutInfo | Add-Member -Type NoteProperty -Name "Queue" -Value ([Math]::Round(([int32]($counters | ?{$_.Path -eq $nodeName+$diskQueue}).CookedValue),2))
    $outPutInfo | Add-Member -Type NoteProperty -Name "Avg Read Queue" -Value ([Math]::Round(([int32]($counters | ?{$_.Path -eq $nodeName+$diskReadQueue}).CookedValue),2))
    $outPutInfo | Add-Member -Type NoteProperty -Name "Avg Write Queue" -Value ([Math]::Round(([int32]($counters | ?{$_.Path -eq $nodeName+$diskWriteQueue}).CookedValue),2))
    $outPutInfo | Add-Member -Type NoteProperty -Name "Transfers/sec" -Value  ([Math]::Round(([int32]($counters | ?{$_.Path -eq $nodeName+$diskTransfers}).CookedValue).2))

    $outPutInfo | Add-Member -Type NoteProperty -Name "Disk Idle" -Value ([Math]::Round(([int32]($counters | ?{$_.Path -eq $nodeName+$diskIdle}).CookedValue),2))
    return $outPutInfo;
}

    [System.Collections.ArrayList]$collection = @()
    Write-Host ("Sample interval has been set to {0}" -f $sampleInternval)
    while ($1 -ne 5)
    {
        #Counter Queries
        $counters = ((Get-Counter -Counter "\LogicalDisk(*)\Current Disk Queue Length", 
        "\LogicalDisk(*)\% Disk Time",
        "\LogicalDisk(*)\Disk Reads/sec",
        "\LogicalDisk(*)\Disk Writes/sec",
        "\LogicalDisk(*)\Disk Read Bytes/sec",
        "\LogicalDisk(*)\Disk Write Bytes/sec",
        "\LogicalDisk(*)\Avg. Disk Read Queue Length",
        "\LogicalDisk(*)\Avg. Disk Write Queue Length",
        "\LogicalDisk(*)\Disk Transfers/sec",
        "\LogicalDisk(*)\% Idle Time" -SampleInterval $sampleInternval -ErrorAction SilentlyContinue).CounterSamples | Group-Object InstanceName).Group

        $uniqueDrives = $counters | select InstanceName -Unique
        $collection.clear()
        foreach ($drive in $uniqueDrives.InstanceName)
        {
            $output = (Get-DiskPerf -Path $drive)

           $collection.Add($output) | Out-Null
        }
        cls
        $collection | ft -a
  
    }
  
    

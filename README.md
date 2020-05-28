# psperf
A simple collection of Powershell related scripts to help identify potential performance impacting events on a Windows core system. Keep in mind that there are some averaging that takes place by default with the Perf Metrics being used here, if demand is high enough we can switch over to xperf and design some wrappers to make use and consumption of the event tracing easier for all.

``Not all scripts have been vetted, only the ones verifed will be uploaded. Contact for additional information.``

# pstop
A simple Windows System performance analysis tool for Powershell to start looking at heavy CPU and Memory consuming processes as well as their disk impact. Run alone for single second samples or specify a sample interval. 

``Note`` right now the sample intervals over 1 are not going to display the min/max/average, only the total. Keep in mind this may not show true peaks.

![image](https://github.com/D3athByMonkey/psperf/blob/master/images/pstopexample.png?raw=true)

# How to use this
Once you're in powershell you can either save it and run it locally by running:
* Invoke-WebRequest -UseBasicParsing -Uri https://raw.githubusercontent.com/D3athByMonkey/psperf/master/pstop.ps1 -OutFile pstop.ps1
* .\pstop.ps1

or just run it using:
*  Invoke-WebRequest -UseBasicParsing -Uri https://raw.githubusercontent.com/D3athByMonkey/psperf/master/pstop.ps1 | Invoke-Expression

#to do

network

disk

container

etc

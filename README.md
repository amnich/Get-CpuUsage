# Get-CpuUsage
.SYNOPSIS
 
 Get average CPU usage over a period of time. 

.DESCRIPTION
  
  Get average CPU usage over a period of time using Get-Counter and average per core using Get-WmiObject. 
 
  Can be used on multiple computers at once. Running on local PC seperate from remote machines.

  Returned is an average value and single readings.

.PARAMETER PerCore	
 
   Get results per core and in total

.EXAMPLE
```PowerShell
		PS C:\> Get-CpuUsage -ComputerName COMPUTER2 -SampleInterval 1 -MaxSamples 5
    
		ComputerName Name   Average
		------------ ----   -------
		COMPUTER2    _Total 23,23
```
.EXAMPLE
```PowerShell
		PS C:\> $results = Get-CpuUsage -ComputerName COMPUTER2 -SampleInterval 1 -MaxSamples 5
		PS C:\> $results.SingleReadings
		
		TimeStamp                Cookedvalue Name  
		---------                ----------- ----  
		2018-03-07 13:12:03 34,8307210757895 _Total
		2018-03-07 13:12:04 39,4556991872146 _Total
		2018-03-07 13:12:05 42,6071994534768 _Total
		2018-03-07 13:12:06 33,2035942544808 _Total
		2018-03-07 13:12:07 33,6261072727046 _Total
```
.EXAMPLE
```PowerShell
		PS C:\> Get-CpuUsage -SampleInterval 2 -MaxSamples 5 -PerCore
		
		ComputerName Name   Average
		------------ ----   -------
		COMPUTER1    _Total 13     
		COMPUTER1    0      9,6    
		COMPUTER1    1      8,6    
		COMPUTER1    2      12,2   
		COMPUTER1    3      21    
 ```

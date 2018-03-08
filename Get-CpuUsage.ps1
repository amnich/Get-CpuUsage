Function Get-CpuUsage {
<#
	.SYNOPSIS
		Get average CPU usage over a period of time. 
		
	.DESCRIPTION
		Get average CPU usage over a period of time using Get-Counter and average per core using Get-WmiObject. 
		Can be used on multiple computers at once. Running on local PC seperate from remote machines.
		Returned is an average value and single readings.
	
	.PARAMETER PerCore	
		Get results per core and in total
	
	.EXAMPLE
		PS C:\> Get-CpuUsage -ComputerName COMPUTER2 -SampleInterval 1 -MaxSamples 5
		
		ComputerName Name   Average
		------------ ----   -------
		COMPUTER2    _Total 23,23
	
	.EXAMPLE
		PS C:\> $results = Get-CpuUsage -ComputerName COMPUTER2 -SampleInterval 1 -MaxSamples 5
		PS C:\> $results.SingleReadings
		
		TimeStamp                Cookedvalue Name  
		---------                ----------- ----  
		2018-03-07 13:12:03 34,8307210757895 _Total
		2018-03-07 13:12:04 39,4556991872146 _Total
		2018-03-07 13:12:05 42,6071994534768 _Total
		2018-03-07 13:12:06 33,2035942544808 _Total
		2018-03-07 13:12:07 33,6261072727046 _Total
		
	.EXAMPLE
		PS C:\> Get-CpuUsage -SampleInterval 2 -MaxSamples 5 -PerCore
		
		ComputerName Name   Average
		------------ ----   -------
		COMPUTER1    _Total 13     
		COMPUTER1    0      9,6    
		COMPUTER1    1      8,6    
		COMPUTER1    2      12,2   
		COMPUTER1    3      21     
		
#>

 [CmdletBinding()]  
Param 
( 
    [parameter(ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)] 
    [alias("CN","Computer")] 
    [String[]]$ComputerName=$Env:COMPUTERNAME, 
    [int]$SampleInterval = 1,
	[int]$MaxSamples = 1,
	[switch]$PerCore,
	[Alias('Cred')][System.Management.Automation.PSCredential]$Credential
) 
	BEGIN {
		$scriptblock = {
			try {
				if ($using:SampleInterval){
					$SampleInterval = $using:SampleInterval
					$MaxSamples = $using:MaxSamples
					$PerCore = $using:PerCore
				}
			
			}
			catch{}
			if ($PerCore){
				$i=0
				$results = while ($i -lt $MaxSamples){
					$res = Get-WmiObject -Query "select Name, PercentProcessorTime from Win32_PerfFormattedData_PerfOS_Processor" 
					$now = Get-Date
					foreach ($single in $res){
						New-Object pscustomobject -Property @{
							TimeStamp = $now
							Cookedvalue = $single.PercentProcessorTime
							Name = $single.Name
						}
					}
					Start-Sleep -Seconds $SampleInterval
					$i++
				}
				$results | 
					group Name | 
					foreach {$r = $_.Group | 
						Measure-Object -Average -Property Cookedvalue
						$object = New-Object pscustomobject -Property @{
							Name = $_.Name
							Average = [Math]::Round($r.average,2)
							ComputerName = $env:computername
							SingleReadings = Foreach ($single in $_.group){
								New-Object PSCustomObject -Property @{
									TimeStamp = $single.TimeStamp
									Cookedvalue = $single.Cookedvalue
									Name = $single.Name
								}
							}
						}
						$object.PSObject.TypeNames.Insert(0,'My.CpuUsage')							
						$object
					}
			}
			else{
				$data = Get-Counter -Counter "\238(_Total)\6" -SampleInterval $SampleInterval -MaxSamples $MaxSamples 
				$counter = (($data.countersamples).cookedvalue | Measure-Object -Average).average
				$object =  New-Object PSCustomObject -Property @{
					ComputerName = $Env:COMPUTERNAME
					Name = "_Total"
					Average = [Math]::Round($counter,2)
					Data = $data
					SingleReadings = Foreach ($single in $data){
						New-Object PSCustomObject -Property @{
							TimeStamp = $single.CounterSamples[0].TimeStamp
							Cookedvalue = $single.CounterSamples[0].Cookedvalue
							Name = "_Total"
						}
					}		
				}
				$object.PSObject.TypeNames.Insert(0,'My.CpuUsage')							
				$object
			}
		}
	}
	PROCESS{
		$parameters = @{
			ComputerName = $($ComputerName | Where-Object {!($_.toupper().Contains($env:COMPUTERNAME.toupper())) -and !($_.toupper().Contains("LOCALHOST"))})
			ScriptBlock = $scriptblock
		}
		if ($credential){
			$parameters += @{'Credential'=$Credential}
		}
		if ($ComputerName | Where-Object {!($_.toupper().Contains($env:COMPUTERNAME.toupper())) -and !($_.toupper().Contains("LOCALHOST"))}){
			Invoke-Command @parameters 											
		}
		if ($computername.toupper().Contains($env:COMPUTERNAME.toupper()) -or $computername.toupper().Contains("LOCALHOST")){
			Write-Verbose "Running on local computer ..."
			& $scriptblock
		}
	}
}

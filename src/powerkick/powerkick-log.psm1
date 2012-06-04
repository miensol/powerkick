function Get-Log {
	[CmdLetBinding()]
	param(		
		[Parameter(Position = 0, Mandatory = 0)]
		[string] $loggerName = ((Get-PSCallStack)[0].Command)
	)	
	New-Object psobject |
		Add-Member -Name "Info" -MemberType ScriptMethod {
			param([string] $message)
			Log $message "Info" $this.Name			
		} -PassThru |
		Add-Member -Name "Debug" -MemberType ScriptMethod {
			param([string] $message)
			Log $message "Debug" $this.Name	-ForegroundColor DarkGray				
		} -PassThru |		
		Add-Member -Name "Warning" -MemberType ScriptMethod {
			param([string] $message)
			Log $message "Warning" $this.Name -ForegroundColor Yellow
		} -PassThru |		
		Add-Member -Name "Error" -MemberType ScriptMethod {
			param([string] $message)
			Log $message "Error" $this.Name	-ForegroundColor Red		
		} -PassThru |		
		Add-Member -Name "Name" -MemberType NoteProperty -Value $loggerName -PassThru
}

function Log-ToFile {
	param([string]$message)	
	$logFile = 'log.txt'
	if(!(Test-Path $logFile -PathType Leaf)){
		New-Item $logFile -ItemType file -WhatIf:$false
	}
	Add-Content -Value $message -Path $logFile -WhatIf:$false
}

function Log {
	[CmdLetBinding()]
	param([string]$message, [string]$severity, [string]$logger,[consolecolor]$ForegroundColor=(Get-Host).UI.RawUI.ForegroundColor)
	Write-Host ("{0} - [{1}] - {2}" -f $severity, $logger, $message) -ForegroundColor $ForegroundColor
	Log-ToFile ("{0} - $severity - [$logger] - {1}" -f (Get-Date),$message)		
}

Export-ModuleMember -Function Get-Log


function Get-Logger {
	[CmdLetBinding()]
	param(		
		[Parameter(Position = 0, Mandatory = 0)]
		[string] $loggerName = ((Get-PSCallStack)[1].Command)
	)	
	$object = New-Object object |
		Add-Member 
}

Export-ModuleMember -Function Get-Logger


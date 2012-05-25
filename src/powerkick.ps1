param(	
	[Parameter(Position=0, Mandatory=0)]
	[string]$environment = 'Dev',
	[string]$planFile = $(Join-Path (Split-Path -Parent $MyInvocation.MyCommand.path) plan.ps1),
	[string]$scriptPath = $(Split-Path -Parent $MyInvocation.MyCommand.path)
)


'[p]owerkick', '[p]owerkick-deploymentplan', '[p]owerkick-log' | 
	%{ Remove-Module $_ }
'powerkick-log.psm1', 'powerkick.psm1', 'powerkick-deploymentplan.psm1' |
	%{ Join-Path $scriptPath "powerkick\$_"} |
	%{ Import-Module $_ }


Invoke-powerkick $planFile $environment
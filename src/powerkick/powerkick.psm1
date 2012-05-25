$script:powerkick = @{
	roles = @();
	settings= @{};
}


function Load-Settings {
	param(
		[string]$environment,
		[Parameter(Mandatory=1)]
		[string]$settingsPath
	)
	$log = Get-Logger
	write-host ($log.Info | Get-Member)
	$settingsFile = Join-Path $settingsPath "$environment.ps1"		
	try {			
		
		. $settingsFile			
	}catch{
		throw "Error reading settings file $_.Exception"
	}
}



function Invoke-powerkick {
	[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=1)]
		[string]$planFile,
		[Parameter(Position=1, Mandatory=1)]
		[string]$environment
	)
	Load-Settings $environment (Join-Path (Split-Path -Parent $planFile) settings)
	$powerkick.settings.environment = $environment;
	. $planFile
	
	foreach($role in $powerkick.roles){		
		. $role
	}
}


Export-ModuleMember -Variable powerkick -Function Invoke-powerkick



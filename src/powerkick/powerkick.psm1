$script:powerkick = @{
	roles = @();
	settings= @{};
}

#borrowed from Jeffrey Snover http://blogs.msdn.com/powershell/archive/2006/12/07/resolve-error.aspx
function Resolve-Error($ErrorRecord = $Error[0]) {
    $error_message = "`nErrorRecord:{0}ErrorRecord.InvocationInfo:{1}Exception:{2}"
    $formatted_errorRecord = $ErrorRecord | format-list * -force | out-string
    $formatted_invocationInfo = $ErrorRecord.InvocationInfo | format-list * -force | out-string
    $formatted_exception = ""
    $Exception = $ErrorRecord.Exception
    for ($i = 0; $Exception; $i++, ($Exception = $Exception.InnerException)) {
        $formatted_exception += ("$i" * 70) + "`n"
        $formatted_exception += $Exception | format-list * -force | out-string
        $formatted_exception += "`n"
    }

    return $error_message -f $formatted_errorRecord, $formatted_invocationInfo, $formatted_exception
}

function Get-ServerMap {
	param(
		[string]$environment,
		[Parameter(Mandatory=1)]
		[string]$settingsPath
	)
	$log = (Get-Log)
	$serverMapFile = Join-Path $settingsPath "$environment-ServerMap.ps1"
	$serverMap = $null
	$log.Debug("Reading server map from $serverMapFile")
	. $serverMapFile
	if(! $serverMap){
		throw "Could not read valid serverMap from file $serverMapFile"
	}
	return $serverMap
}

function Get-Settings {
	param(
		[string]$environment,
		[Parameter(Mandatory=1)]
		[string]$settingsPath
	)
	$log = Get-Log
	$settingsFile = Join-Path $settingsPath "$environment.ps1"			
	$settings = $null
	
	$log.Debug("Reading settings file {0}" -f $settingsFile)	
	. $settingsFile					
	
	if(!$settings){		
		throw "The settings file '$settingsFile' is malformed, settings variable is null"
	}
	return $settings
}

function Show-Settings {
	$log = (Get-Log)
	$log.Info("Following settings will be used")
	$powerkick.settings.keys | %{		
		$value = $powerkick.settings[$_];
		if($value -eq '?'){
			$value = "(Will prompt..)"
		}
		$log.Info(("{0}='{1}'" -f $_, $value))	
	}
	
}


function Invoke-Roles {	
	foreach($role in $powerkick.roles){		
		. $role.ExecuteBlock
	}
}

function Invoke-DeploymentPlan {
	[CmdLetBinding()]
	param([switch]$Confirm)
	$log = (Get-Log)
	Show-Settings
	Show-DeploymentPlan
	if($Confirm){
		$continue = 'N'
		do {
			$continue = (Read-Host "Review settings and deployment plan. Continue deployment [Y/N]:");
		}
		while(-not($continue -match '[Y|N]'))
		Write-Host $continue
		if(-not($continue -eq 'Y')){
			$log.Warning("Aborting run..")
			return;
		}
	}
	Invoke-Roles
}
function Set-Environment([string]$ScriptPath){
	$powerkick.originalEnvironment = @{
		Location = (Get-Location);
		ErrorActionPreference = $global:ErrorActionPreference;
	}
	$global:ErrorActionPreference = "Stop"
	Set-Location $scriptPath
	Set-NetLocation $scriptPath
}
function Restore-Environment {
	$orignalEnvironment = $powerkick.originalEnvironment
	Set-Location $orignalEnvironment.Location
	Set-NetLocation $orignalEnvironment.Location
	$global:ErrorActionPreference = $orignalEnvironment.ErrorActionPreference 
}


function Invoke-powerkick {
	[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=1)]
		[string]$PlanFile,
		[Parameter(Position=1, Mandatory=1)]
		[string]$Environment,
		[Parameter(Position=2, Mandatory=1)]
		[string[]]$Roles,
		[Parameter(Position=3, Mandatory=1)]
		[string]$ScriptPath
	)
	try {
		Set-Environment $ScriptPath
		$log = (Get-Log)
		$settingsPath = (Join-Path (Split-Path -Parent $PlanFile) settings)	
		$powerkick.settings = Get-Settings $Environment $settingsPath
		$powerkick.serverMap = Get-ServerMap $Environment $settingsPath
		$powerkick.settings.environment = $Environment	
		Read-Plan $PlanFile		
		Initialize-DeploymentPlan $Roles
		Invoke-DeploymentPlan -Confirm	
	}catch {
		$log.Error("Deployment script ended abruptly, review log files to diagnose")		
		$log.Error( (Resolve-Error $_) )
	}finally{
		Restore-Environment
	}
	
}


Export-ModuleMember -Variable powerkick -Function Invoke-powerkick



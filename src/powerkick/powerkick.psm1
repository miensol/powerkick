$script:powerkick = @{
	roles = @();
	settings= @{};
}
$local:path = (Split-Path -Parent $MyInvocation.MyCommand.Path)
Import-Module "$local:path\powerkick-deploymentplan.psm1"
Import-Module "$local:path\powerkick-files.psm1"
Import-Module "$local:path\powerkick-log.psm1"

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
		$log.Info(("{0}={1}" -f $_, $value))	
	}
	
}

function Initialize-RemainingSettings {
	$log = (Get-Log)	
	$keys = $powerkick.settings.keys | Where { ($powerkick.settings[$_] -eq '?') }
	if($keys){
		$log.Debug("Prompting for missing settings values")
		$keys | %{				
			while(($powerkick.settings[$_] -eq '?') -or -not($powerkick.settings[$_])){
				$powerkick.settings[$_] = Read-Host "Value for setting '$_'"
			}
		} | Out-Null
		$log.Debug("Done prompting for missing settings")
	}		
}

function Confirm-DeploymentShouldRun {
	[CmdLetBinding()]
	param([switch]$Confirm)
	if(-not $Confirm){
		return $true
	}
	$continue = 'N'
	do {$continue = (Read-Host "Review settings and deployment plan. Continue deployment [Y/N]:");}
	while(-not($continue -match '[Y|N]'))	
	($continue -eq 'Y')						
}

function Write-DeploymentSteps($steps){
	([string]::Join(", ", ($steps | %{ ("{0}->{1}" -f $_.role.Name,$_.server) })))
}

function Invoke-DeployRole {
	[CmdLetBinding()]
	param($Role, [string]$Server)	
	. $Role.ExecuteBlock
}

function Invoke-RollbackRole {
	[CmdLetBinding()]
	param($Role, [string]$Server)	
	. $Role.RollbackBlock
}

function Invoke-DeploymentRun {
	$log = (Get-Log)
	$deployedSteps = @()
	$rollbackSteps = @()
	try{
		foreach($deployStep in (Get-DeploymentPlan)){
			$log.Info(("Deploying {0} to {1}" -f $deployStep.role.Name,$deployStep.server))		
			$deployedSteps += $deployStep		
			
			Invoke-DeployRole $deployStep.role $deployStep.server 
			
			$log.Info(("Successfully deployed {0} to {1}" -f $deployStep.role.Name,$deployStep.server))
		}
	}catch{
		$log.Error(("Deployment of {0} to {1} ended with error" -f $deployStep.role.Name,$deployStep.server))
		$log.Error((Resolve-Error $_))		
		$rollbackSteps = $deployedSteps | Sort -Descending		
	}		
	if($rollbackSteps){
		$log.Warning(("Will try to rollback following roles: {0}" -f (Write-DeploymentSteps $rollbackSteps)))
		$errorSteps = @()
		foreach($rollbackStep in $rollbackSteps){			
			try {
				$log.Info(("Rolling back {0} on {1}" -f $rollbackStep.role.Name, $rollbackStep.server))
				Invoke-RollbackRole $rollbackStep.role $rollbackStep.server
				$log.Info(("Done rolling back {0} on {1}" -f $rollbackStep.role.Name, $rollbackStep.server))
			}catch {
				$errorSteps += $rollbackStep
				$log.Error(("Rollback of {0} on {1} ended with error" -f $rollbackStep.role.Name, $rollbackStep.server))
				$log.Error( (Resolve-Error $_) )
				$log.Warning("Will try to rollback remaining steps")
			}
		}
		if($errorSteps){
			throw ("Rollback failed for following roles: {0}" -f (Write-DeploymentSteps $errorSteps))						
		}
		$log.Warning("Successfuly rolled back")
	}
}

function Invoke-DeploymentPlan {
	[CmdLetBinding()]
	param([switch]$Confirm)
	$log = (Get-Log)
	Initialize-RemainingSettings
	Show-Settings
	Show-DeploymentPlan
	if(-not(Confirm-DeploymentShouldRun -Confirm:$Confirm)){
		$log.Warning("Aborting deployment")
		return
	}	
	Invoke-DeploymentRun
}
function Set-Environment([string]$ScriptPath,[bool]$WhatIf=$false,[bool]$EnableTranscript=$false){	
	$powerkick.originalEnvironment = @{
		Location = (Get-Location);
		ErrorActionPreference = $global:ErrorActionPreference;
		WhatIfPreference = $global:WhatIfPreference;				
		TranscriptEnabled = $false
	}	
	$global:ErrorActionPreference = "Stop"	
	Set-Location $scriptPath
	Set-NetLocation $scriptPath
	if($EnableTranscript -and(Start-Transcript "transcript.log.txt" -ErrorAction SilentlyContinue)){
		$powerkick.originalEnvironment.TranscriptEnabled = $true
	}
	$global:WhatIfPreference = $WhatIf
}
function Restore-Environment {
	if($powerkick.originalEnvironment){
		$orignalEnvironment = $powerkick.originalEnvironment
		$global:WhatIfPreference = $orignalEnvironment.WhatIfPreference
		Set-Location $orignalEnvironment.Location
		Set-NetLocation $orignalEnvironment.Location
		$global:ErrorActionPreference = $orignalEnvironment.ErrorActionPreference 		
		if($orignalEnvironment.TranscriptEnabled){
			Stop-Transcript -ErrorAction SilentlyContinue
		}
	}	
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
		[string]$ScriptPath,
		[Parameter(Position=4, Mandatory=1)]
		[switch]$WhatIf = $false,
		[Parameter(Position=5, Mandatory=1)]
		[switch]$EnableTranscript = $false,
		[Parameter(Position=6, Mandatory=0)]
		[switch]$Confirm = $false
	)
	try {		
		Set-Environment $ScriptPath $WhatIf	$EnableTranscript
		$log = (Get-Log)
		$settingsPath = (Join-Path (Split-Path -Parent $PlanFile) settings)	
		$powerkick.settings = Get-Settings $Environment $settingsPath
		$powerkick.serverMap = Get-ServerMap $Environment $settingsPath
		$powerkick.settings.environment = $Environment	
		Read-Plan $PlanFile		
		Initialize-DeploymentPlan $Roles
		Invoke-DeploymentPlan -Confirm:$Confirm
	}catch {	
		$log.Error("Deployment script ended abruptly, review log files to diagnose")		
		$log.Error( (Resolve-Error $_) )
	}finally{
		Restore-Environment
	}
	
}


Export-ModuleMember -Variable powerkick -Function Invoke-powerkick



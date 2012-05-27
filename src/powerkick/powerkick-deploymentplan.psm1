function Read-Plan {
	param(
		[Parameter(Position=0, Mandatory=1)]
		[string]$planFile )
	. $planFile
}

function Initialize-DeploymentPlan([string[]]$Roles) {
	$log = (Get-Log)
	if( -not(($Roles.Length -eq 1) -and ($Roles[0] -eq 'All'))){
		[void]$Roles | %{
			if(-not(Find-Role $_)){
				throw "You have specified to deploy a role named: $_, but it could not be found in the deployment plan"
			}						
		}
		$powerkick.roles = ($powerkick.roles | Where { $Roles -contains $_.Name })
	}
	$powerkick.deploymentPlan = @()
	$powerkick.roles | %{
		$roleName = $_.Name
		if( -not($powerkick.serverMap.ContainsKey($roleName))){
			throw "A role $roleName has no entry in serverMap file" 
		}
		
		(Find-ServersForRole $roleName) | % {			
			$powerkick.deploymentPlan += @{
				'role' = (Find-Role $roleName);
				'server' = $_;
			};								
		}
	}		
}
function Show-DeploymentPlan {
	$log = (Get-Log)
	$log.Info("Will execute following deployment plan:")
	$powerkick.deploymentPlan | % {				
		$log.Info(("Deploy '{0}' to '{1}'" -f $_.role.Name,$_.server))
	}
}

function Find-Role([string]$Name){	
	$powerkick.roles | Where { ($_.Name -eq $Name) } | Select-Object -First 1	
}

function Find-ServersForRole([string]$RoleName){
	if($powerkick.serverMap.ContainsKey($RoleName)){
		$powerkick.serverMap.$RoleName
	}else {
		@()
	}
}

function Role {
	[CmdLetBinding()]
	param(
		[Parameter(Position=0, Mandatory=1)]
		[string]$Name,
		[Parameter(Position=1, Mandatory=1)]
		[scriptblock]$ScriptBlock = {}
	)	
	if((Find-Role $Name)){
		throw "There already is a Role with name $Name"
	}
	$powerkick.roles += @{
		Name = $Name;
		ExecuteBlock = $ScriptBlock;
	}
}

Export-ModuleMember -Function Role, Initialize-DeploymentPlan, Show-DeploymentPlan, Read-Plan
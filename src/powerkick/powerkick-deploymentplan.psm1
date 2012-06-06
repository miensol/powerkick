$local:path = (Split-Path -Parent $MyInvocation.MyCommand.Path)
Import-Module "$local:path\powerkick-log.psm1"

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

function Test-Administrator {  
	$currentPrincipal = New-Object Security.Principal.WindowsPrincipal( [Security.Principal.WindowsIdentity]::GetCurrent() )    
    $currentPrincipal.IsInRole( [Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-TargetServer([string]$ServerName){

	if(-not(Test-Connection $ServerName -Quiet -Count 1)){
		"Could not connect to $ServerName with ICMP request"
	}
	if(-not(Test-IsLocal $ServerName)){		
		try {
			if(-not(Test-WSMan $ServerName)){
				"Windows Remote Management is not enabled on $ServerName"
			}
			$result = (Invoke-Command -ComputerName $ServerName { 
				$currentPrincipal = New-Object Security.Principal.WindowsPrincipal( [Security.Principal.WindowsIdentity]::GetCurrent() )    
    			$currentPrincipal.IsInRole( [Security.Principal.WindowsBuiltInRole]::Administrator)
			})			
			if(!$result){
				"You are not administrator on $ServerName"
			}
		}catch{
			"Could not invoke remote command on $ServerName this may indicate that Windows Remote Management is not enabled on $ServerName"
		}
	}else{
		if(-not(Test-Administrator)){
			"You are not administrator on $ServerName"
		}
	}		
}

function Get-DeploymentPlan {
	$powerkick.deploymentPlan
}

function Show-DeploymentPlan {
	$log = (Get-Log)
	$log.Info("Will execute following deployment plan:")
	Get-DeploymentPlan | % {				
		$log.Info(("Deploy '{0}' to '{1}'" -f $_.role.Name,$_.server))
		Test-TargetServer $_.server | %{ $log.Warning($_) }		
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
		[scriptblock]$Execute = {},
		[Parameter(Position=2, Mandatory=0)]
		[scriptblock]$Rollback = { throw "Rollback not implemented"  }
	)	
	if((Find-Role $Name)){
		throw "There already is a Role with name $Name"
	}
	$powerkick.roles += @{
		Name = $Name;
		ExecuteBlock = $Execute;
		RollbackBlock = $Rollback;
	}
}

Export-ModuleMember -Function Role, Initialize-DeploymentPlan, Show-DeploymentPlan, Read-Plan,  Get-DeploymentPlan

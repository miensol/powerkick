$local:path = (Split-Path -Parent $MyInvocation.MyCommand.Path)
Import-Module "$local:path\powerkick-log.psm1"


function Initialize-WebAppPool {
	[CmdLetBinding()]
	param(
		[Parameter(Position=0, Mandatory=1)]
		[string]$Name = 'Local',
		[Parameter(Position=1, Mandatory=0)]
		[string]$NetVersion = 'v4.0',
		[Parameter(Position=2, Mandatory=0)]
		[string]$UserName = $null,
		[Parameter(Position=3, Mandatory=0)]
		[string]$Password = $null
	)
		
	Import-Module WebAdministration
	$log = (Get-Log)
	if(-not(Get-ChildItem IIS:\AppPools\ | Where {$_.Name -eq $Name} )){
		$log.Info("Creating app pool $Name")
		[void](New-WebAppPool -Name $Name)
	}
	Get-ChildItem IIS:\AppPools\ | Where {$_.Name -eq $Name} |
		ForEach {
			$log.Info("Setting .net version of $($_.Name) pool to $NetVersion")
			$_.managedRuntimeVersion = $NetVersion
			if($UserName -and $Password){
				$log.Info("Changing $($_.Name) identity to SpecificUser")
				$_.processModel.username = $UserName 
				$_.processModel.password = $Password
				$_.processModel.identityType = "SpecificUser"
			}
			[void]($_ | Set-Item)
			$_
		}
}

function Initialize-Website {
	[CmdLetBinding()]
	param(
		[Parameter(Position=0, Mandatory=1)]
		[string]$Name,
		[Parameter(Position=1, Mandatory=1)]
		[string]$AppPool,
		[Parameter(Position=2, Mandatory=1)]
		[string]$PhysicalPath
	)
	Import-Module WebAdministration  
	$log = (Get-Log)
	if(-not(Get-ChildItem iis:\sites | Where { $_.Name -eq $Name})){
		$log.Info("Creating web site $Name")
		New-Website $Name
	}
	Get-ChildItem iis:\sites | Where { $_.Name -eq $Name} |
		ForEach { 
			$_ | Set-ItemProperty -Name ApplicationPool -Value $AppPool 
			$_ | Set-ItemProperty -Name PhysicalPath -Value $PhysicalPath
			$_
		}
}
# TODO: move this to files module and add logging
function Set-AccessRights {
	[CmdLetBinding()]
	param(
		[Parameter(Position=0, Mandatory=1)]
		[string]$Path,
		[Parameter(Position=1, Mandatory=1)]
		[string]$User,
		[Parameter(Position=2, Mandatory=1)]
		[System.Security.AccessControl.FileSystemRights]$Rights,
		[Parameter(Position=3, Mandatory=1)]
		[System.Security.AccessControl.AccessControlType]$AccessType = [System.Security.AccessControl.AccessControlType]::Deny,
		[Parameter(Position=4, Mandatory=0)]
		[System.Security.AccessControl.InheritanceFlags]$Inheritance = [System.Security.AccessControl.InheritanceFlags]::None,
		[Parameter(Position=5, Mandatory=0)]
		[System.Security.AccessControl.PropagationFlags]$Propagation =[System.Security.AccessControl.PropagationFlags]::None
	)

	$objACE = New-Object System.Security.AccessControl.FileSystemAccessRule `
		($User, $Rights, $Inheritance, $Propagation, $AccessType) 

	$objACL = Get-ACL $Path 
	$objACL.AddAccessRule($objACE) 
	(Get-Log).Info("Adding $Rights for $Path to $User")
	Set-ACL $Path $objACL
}

Export-ModuleMember -Function Initialize-Website, Initialize-WebAppPool, Set-AccessRights


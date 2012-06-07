$local:path = (Split-Path -Parent $MyInvocation.MyCommand.Path)
Import-Module "$local:path\powerkick-log.psm1"
Import-Module "$local:path\powerkick-helpers.psm1"

Add-Type -AssemblyName System.ServiceProcess

function New-ServiceOnTarget {
	[CmdLetBinding()]
	param(		
		[Parameter(Position = 0, Mandatory = 1)]
		[string] $BinPath,
		[Parameter(Position = 1, Mandatory = 0)]
		[string] $ServiceName = (Convert-PathToFileNameWithoutExtension $BinPath),
		[Parameter(Position = 2, Mandatory = 0)]
		[string] $DisplayName = ($ServiceName),
		[Parameter(Position = 3, Mandatory = 0)]
		[string] $Description = ($ServiceName),
		[Parameter(Position = 4, Mandatory = 0)]
		[System.ServiceProcess.ServiceStartMode] $StartupType = ([System.ServiceProcess.ServiceStartMode]::Automatic),
		[Parameter(Position = 5, Mandatory = 0)]
		[switch] $StartAfterCreating = $true
	)	
	$log = (Get-Log)
	Assert-ServiceNotExistsOnTarget $ServiceName
	
	$log.Info(("Creating new service {0}" -f $ServiceName))
	
	Invoke-CommandOnTargetServer {
		param($BinPath, $ServiceName, $DisplayName, $Description, $StartupType)
		New-Service -BinaryPathName $BinPath -Name $ServiceName -DisplayName $DisplayName -Description $Description -StartupType $StartupType
	} -ArgumentList $BinPath, $ServiceName, $DisplayName, $Description, $StartupType
	
	$log.Debug(("Done creating new service {0}" -f $ServiceName))
	
	if($StartAfterCreating){
		Start-ServiceOnTarget $ServiceName
	}
}

function Remove-ServiceOnTarget {
	[CmdLetBinding()]
	param(		
		[Parameter(Position = 0, Mandatory = 0)]
		[string] $ServiceName, 					
		[Parameter(Position = 1, Mandatory = 0)]
		[string] $BinPath
	)	
	$log = (Get-Log)
	Assert ($ServiceName -or $BinPath) "You must supply either a ServiceName or BinPath"
	if(!$ServiceName){
		$ServiceName = (Convert-PathToFileNameWithoutExtension $BinPath)
		Assert $ServiceName "The service name could not be inferred from $BinPath"
	}
	Stop-ServiceOnTarget $ServiceName
	$log.Info(("Removing service {0}" -f $ServiceName))
	Invoke-CommandOnTargetServer { 
		param($ServiceName)
		(Get-Service -Name $ServiceName -ErrorAction SilentlyContinue) | %{
			C:\WINDOWS\system32\sc.exe delete $_.DisplayName
		}
	} -ArgumentList $ServiceName
	$log.Debug(("Done removing service {0}" -f $ServiceName))
	$log.Info("Sleeping for 10s because windows can be silly")
	Start-Sleep -Seconds 10
	$log.Debug("Done sleeping")
}

function Start-ServiceOnTarget {
	[CmdLetBinding()]
	param(		
		[Parameter(Position = 0, Mandatory = 1)]
		[string] $ServiceName
	)
	$log = (Get-Log)
	$log.Info("Will start service $ServiceName on {0}" -f (Get-ContextServer))
	
	Start-Service -InputObject $(Get-Service -Name $ServiceName -ComputerName (Get-ContextServer))		
	
	$log.Debug("Done starting service $ServiceName")
	
}



function Stop-ServiceOnTarget {
	[CmdLetBinding()]
	param(		
		[Parameter(Position = 0, Mandatory = 1)]
		[string] $ServiceName
	)
	$log = (Get-Log)
	$targetServer = (Get-ContextServer)
	$log.Info("Will stop service $ServiceName on $targetServer")	
	$serviceToStop = (Get-Service -Name $ServiceName -ComputerName $targetServer -ErrorAction SilentlyContinue)
	if(!$serviceToStop){
		$log.Warning("Could not find service $ServiceName on $targetServer")
	} else {
		Stop-Service -InputObject $serviceToStop
		$log.Debug("Done stoping service $ServiceName")
	}				
}

function New-TopshelfServiceOnTarget {
	[CmdLetBinding()]
	param(		
		[Parameter(Position = 0, Mandatory = 1)]
		[string] $BinPath,		
		[Parameter(Position = 1, Mandatory = 0)]
		[string] $ServiceName = (Convert-PathToFileNameWithoutExtension $BinPath),
		[Parameter(Position = 2, Mandatory = 0)]
		[switch] $StartAfterCreating = $true
	)	
	$log = (Get-Log)
	Assert-ServiceNotExistsOnTarget $ServiceName
	$log.Info(("Creating new Topshelf service {0}" -f $ServiceName))
	
	Invoke-CommandOnTargetServer {
		param($BinPath)
		& $BinPath install 
	} -ArgumentList $BinPath
	$log.Debug(("Done creating new Topshelf service {0}" -f $ServiceName))
	if($StartAfterCreating){
		Start-ServiceOnTarget $ServiceName
	}
}

function Assert-ServiceNotExistsOnTarget([string]$ServiceName){
	$targetServer = Get-ContextServer
	$serviceExists = (Get-Service -ComputerName $targetServer -Name $ServiceName -ErrorAction SilentlyContinue)
	Assert !$serviceExists "A service $ServiceName already exists on $targetServer"
}



function Convert-PathToFileNameWithoutExtension([string]$BinPath){
	[System.IO.Path]::GetFileNameWithoutExtension((Split-Path -Leaf $BinPath))
}

Export-ModuleMember -Function New-ServiceOnTarget, Remove-ServiceOnTarget, Stop-ServiceOnTarget, Start-ServiceOnTarget, New-TopshelfServiceOnTarget


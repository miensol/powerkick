$local:path = (Split-Path -Parent $MyInvocation.MyCommand.Path)
Import-Module "$local:path\powerkick-log.psm1"
Import-Module "$local:path\powerkick-helpers.psm1"

function Copy-File {
	[CmdletBinding()]
	param(
		[Parameter(Position=0,Mandatory=1)]
		[string]$Path,
		[Parameter(Position=1,Mandatory=1)]
		[string]$DestinationDirectory,
		[Parameter(Position=2,Mandatory=0)]
		[string]$RenameTo
	)	
	$logger = (Get-Log)
	$Path = (Get-FullPath $Path)
	$DestinationDirectory = (Convert-PathToPhysicalOnTargetServer $DestinationDirectory)
	
	Assert (Test-Path -PathType Container -Path $DestinationDirectory) "The target of file copy operation '$DestinationDirectory' is not a directory"
	$Destination = $DestinationDirectory
	if($RenameTo){
		$Destination = (Join-Path $DestinationDirectory $RenameTo)		
	}
	$logger.Info("Copying file from $Path to $Destination")
	Copy-Item $Path -Destination $Destination -Force -Recurse
	$logger.Debug("Done copying file form $Path to $Destination")
	
	
}

function Copy-DirectoryContent {
	[CmdletBinding()]
	param(
		[Parameter(Position=0,Mandatory=1)]
		[string]$Path,
		[Parameter(Position=1,Mandatory=1)]
		[string]$Destination,
		[Parameter(Position=2,Mandatory=0)]
		[switch]$ClearDestination
	)		
	$logger = (Get-Log)
	$Path = (Get-FullPath $Path).TrimEnd("\")
	$Path = "$Path\*"		
	$Destination = (Convert-PathToPhysicalOnTargetServer $Destination)
	
	Assert (-not(Test-Path $Destination) -or (Test-Path -PathType Container -Path $Destination)) "The target of file copy operation '$Destination' is not a directory"
	
	if($ClearDestination -and (Test-Path $Destination)){
		$logger.Info("Clearing destination directory $Destination")
		Remove-Item "$Destination\*" -Recurse -Force
	}
	if(!(Test-Path $Destination)){
		$logger.Info("Creating target directory $Destination")
		New-Item -ItemType Directory -Path $Destination
	}
	$logger.Info("Copying files from $Path to $Destination")
	Copy-Item $Path -Destination $Destination -Force -Recurse
	$logger.Debug("Done copying files form $Path to $Destination")
}

function Get-FullPath([string]$Path){
	[IO.Path]::GetFullPath($Path)
}

function Set-NetLocation([string]$Path){
	[IO.Directory]::SetCurrentDirectory($Path)
}

function Convert-PathToPhysicalOnTargetServer([string]$Path){	
	Convert-PathToPhysical $Path (Get-ContextServer)
}

Export-ModuleMember -Function Copy-DirectoryContent, Set-NetLocation, Copy-File
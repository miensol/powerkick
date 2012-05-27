
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
	$Path = (Get-FullPath $Path) 
	$Path = "$Path\*"	
	if((Test-Path $Destination) -and -not(Test-Path -PathType Container -Path $Destination)){	
		throw "The target of file copy operation '$Destination' is not a directory"
	}
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

Export-ModuleMember -Function Copy-DirectoryContent, Set-NetLocation
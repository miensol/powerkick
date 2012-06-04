$local:path = (Split-Path -Parent $MyInvocation.MyCommand.Path)
Import-Module "$local:path\powerkick-deploymentplan.psm1"
Import-Module "$local:path\powerkick-helpers.psm1"

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
	$Destination = (Convert-PathToPhysicalOnTargetServer $Destination)
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

function Test-IsUncPath([string]$Path) {
	$Path.StartsWith("\\")
}
function Convert-PathToPhysicalOnTargetServer([string]$Path){
	Assert $powerkick.context.TargetServer "TargetServer is not set"
	Convert-PathToPhysical $Path $powerkick.context.TargetServer
}
#ideas taken from https://github.com/chucknorris/dropkick/blob/master/product/dropkick/FileSystem/DotNetPath.cs
function Convert-PathToPhysical {
[CmdletBinding()]
	param(
		[Parameter(Position=0,Mandatory=1)]
		[string]$Path,
		[Parameter(Position=1,Mandatory=1)]
		[string]$TargetServer
	)	
	$resultPath = $Path		
	if((Test-IsLocal $TargetServer)){
		if(Test-IsUncPath $resultPath){
			$serviceLocation = $resultPath
			if($resultPath -imatch "(?<front>[\\\\]?.+?)\\(?<shareName>[A-Za-z0-9\+\.\~\!\@\#\$\%\^\&\(\)_\-'\{\}\s-[\r\n\f]]+)\\?(?<rest>.*)"){
				$shareName = $matches["shareName"]
				$shares = (Get-WmiObject Win32_Share | Where-Object {$_.Name -eq $shareName})
				if(!$shares){
					throw "There is no share named $shareName on local machine"
				}
				$serviceLocation = $shares.Path
			}
			$rest = $matches["rest"]
			$resultPath = (Join-Path $serviceLocation $rest)
		}
	}else{
		if( -not(Test-IsUncPath $resultPath)){
			$resultPath = "\\$TargetServer\$resultPath"
		}		
		$resultPath = $resultPath.Replace(':','$')
	}	
	$resultPath
}

Export-ModuleMember -Function Copy-DirectoryContent, Set-NetLocation, Convert-PathToPhysical
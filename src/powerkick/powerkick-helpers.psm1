$local:path = (Split-Path -Parent $MyInvocation.MyCommand.Path)
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

#borowed from https://github.com/psake/psake/blob/master/psake.psm1
function Exec {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=1)][scriptblock]$cmd,
        [Parameter(Position=1,Mandatory=0)][string]$errorMessage = ("command {0} returned failure status code" -f $cmd),
		[Parameter(Position=2,Mandatory=0)][switch]$WhatIf=$global:WhatIfPreference
    )
	$log = (Get-Log)
	if($WhatIf){
		$message = ("{0}" -f $cmd)
		$log.Info($message)
		Write-Host ("What if: {0}" -f $message)
	}else{
	    & $cmd
	    if ($lastexitcode -ne 0) {
	        throw ("Exec: " + $errorMessage)
	    }
	}
}
#borowed from https://github.com/psake/psake/blob/master/psake.psm1
function Assert {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=1)]$conditionToCheck,
        [Parameter(Position=1,Mandatory=1)]$failureMessage
    )
    if (!$conditionToCheck) { 
        throw ("Assert: " + $failureMessage) 
    }
}


function Test-IsLocal([string]$Server){
	($Server -eq "localhost") -or ($Server -eq $Env:COMPUTERNAME)
}

#ideas taken from https://github.com/chucknorris/dropkick/blob/master/product/dropkick/FileSystem/DotNetPath.cs
function Convert-PathToPhysical {
	[CmdletBinding()]
	param(
		[Parameter(Position=0,Mandatory=1)]
		[string]$Path,
		[Parameter(Position=1,Mandatory=1)]
		[string]$TargetServer,
		[Parameter(Position=2,Mandatory=0)]
		[switch]$ForceRemote = $false
	)	
	$resultPath = $Path		
	if((Test-IsLocal $TargetServer) -and(-not($ForceRemote))){
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

function Test-IsUncPath([string]$Path) {
	$Path.StartsWith("\\")
}

function Get-FullPath([string]$Path){
	[IO.Path]::GetFullPath($Path)
}

function Invoke-CommandOnTargetServer {
	[CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=1)][scriptblock]$Command,
        [Parameter(Position=1,Mandatory=0)]$ArgumentList = @()
    )
	$log = (Get-Log)	
	$targetServer = (Get-ContextServer)
	$logMessage = ("command on server {0}: {1} -ArgumentList {2}" -f $targetServer, $Command, [string]::Join(', ', $ArgumentList ))
	if((Test-IsLocal $targetServer)){
		$log.Debug("Invoking local $logMessage")		
		$Command.Invoke($ArgumentList)
		$log.Debug("Done invoking local $logMessage")		
	} else {	
		$Params = @{
			ArgumentList = $ArgumentList;
			Command = $Command;
			WhatIf = $global:WhatIfPreference;			
			ModulesToImport = Get-Module | 
				Where { $_.Name -match 'powerkick-'} |
				%{ 
					@{
						Name = "$($_.Name).psm1";
						Content = (Get-Content $_.Path);
					};
				};
			LogFileName = (Split-Path -Leaf (Get-LogFile));
			Helpers = $powerkick.helpers;
		};		
		[scriptblock]$wrappedCommand = {
			param($Params)			
			$global:ErrorActionPreference = "Stop"	
			$tempFolder = [System.IO.Path]::GetTempPath()									
			$Params.ModulesToImport | %{ 								
				$_.Content | Out-File (Join-Path $tempFolder $_.Name) -Force
			}			
			Set-ExecutionPolicy Unrestricted -Scope Process
			$Params.ModulesToImport | %{ Import-Module (Join-Path $tempFolder $_.Name) }	
			Set-LogFileName $Params.LogFileName 
			$log = (Get-Log)
			$result = @{ LogFileName = (Get-LogFile);};
			$log.Info("Entered remote machine $env:COMPUTERNAME")
			$global:WhatIfPreference = $Params.WhatIf						
			$blockToExecute = [scriptblock]::Create($Params.Command)												
			try{
				[scriptblock]$helpers = [scriptblock]::Create($Params.Helpers)
				. $helpers
				$result.BlockResult = $blockToExecute.Invoke([array]$Params.ArgumentList)				 
			}catch{
				$log.Error(("Error occured while executing command {0}: {1}" -f $Params.Command, $_))				
				$result.Exception = $_				
			}
			$log.Info("Leaving remote machine $env:COMPUTERNAME")
			return $result
		}		
		$log.Debug("Invoking remote $logMessage")		
		$remoteResult = Invoke-Command -ScriptBlock $wrappedCommand -ComputerName $targetServer -ArgumentList $Params		
		
		Add-RemoteLogToLocalSafely $remoteResult.LogFileName
		
		$log.Debug(("Done invoking remote $logMessage"))		
		Remove-FileOnTargetServer $remoteResult.LogFileName 
		if($remoteResult.Exception){
			throw $remoteResult.Exception
		}else{
			return $remoteResult.BlockResult
		}		
	}
}

function Add-RemoteLogToLocalSafely($localLogName) {
	try {
		Add-ContentToLogFile (Get-ContentOfFileOnTargetServer $localLogName)
	}catch {
		(Get-Log).Warning("Failed while retreiving log file")
	}
}


function Test-Administrator {  
	$currentPrincipal = New-Object Security.Principal.WindowsPrincipal( [Security.Principal.WindowsIdentity]::GetCurrent() )    
    $currentPrincipal.IsInRole( [Security.Principal.WindowsBuiltInRole]::Administrator)
}


Export-ModuleMember -Function Assert, Exec, Resolve-Error, Test-IsLocal, Invoke-CommandOnTargetServer, Convert-PathToPhysical, Test-Administrator, Get-FullPath
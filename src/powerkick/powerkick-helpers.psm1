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
        [Parameter(Position=1,Mandatory=0)][string]$errorMessage = ("command {0} returned failure status code" -f $cmd)
    )
    & $cmd
    if ($lastexitcode -ne 0) {
        throw ("Exec: " + $errorMessage)
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

function Invoke-CommandOnTargetServer {
	[CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=1)][scriptblock]$Command,
        [Parameter(Position=1,Mandatory=0)]$ArgumentList
    )
	$log = (Get-Log)	
	$targetServer = (Get-ContextServer)
	if((Test-IsLocal $targetServer)){
		$Command.Invoke($ArgumentList)
	} else {
		$logMessage = ("command on server {0}: {1} -ArgumentList {2}" -f $targetServer, $Command, $ArgumentList )
		$log.Info(("Invoking {0}" -f $logMessage))
		Invoke-Command -ScriptBlock $Command -ComputerName $targetServer -ArgumentList $ArgumentList
		$log.Debug(("Done invoking {0}" -f $logMessage))
	}
}

Export-ModuleMember -Function Assert, Exec, Resolve-Error, Test-IsLocal, Invoke-CommandOnTargetServer
[CmdLetBinding()]
param(	
	[Parameter(Position=0, Mandatory=0)]
	[string]$Environment = 'Dev',
	[Parameter(Position=1, Mandatory=0)]
	[string[]]$Roles = @('All'),
	[Parameter(Position=2, Mandatory=0)]
	[string]$PlanFile = $(Join-Path (Split-Path -Parent $MyInvocation.MyCommand.path) plan.ps1)
)
$scriptPath = $(Split-Path -Parent $MyInvocation.MyCommand.path)
cls
$global:ErrorActionPreference = "Stop"
'[p]owerkick', '[p]owerkick-deploymentplan', '[p]owerkick-log' | 
	%{ Remove-Module $_ }
'powerkick-log.psm1', 'powerkick.psm1', 'powerkick-deploymentplan.psm1', 'powerkick-files.psm1' |
	%{ Join-Path $scriptPath "powerkick\$_"} |
	%{ Import-Module $_ }

$currentDir = (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $currentDir
Set-NetLocation $currentDir 

Invoke-powerkick $PlanFile $Environment -Roles $Roles

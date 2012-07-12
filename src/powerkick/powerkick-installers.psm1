$local:path = (Split-Path -Parent $MyInvocation.MyCommand.Path)
Import-Module "$local:path\powerkick-log.psm1"


function Get-Framework-Versions {
    if(Test-RegistryKey "HKLM:\Software\Microsoft\.NETFramework\Policy\v1.0" "3705") { "1.0" }
    if(Test-RegistryKey "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v1.1.4322" "Install") { "1.1" }
    if(Test-RegistryKey "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v2.0.50727" "Install") { "2.0" }
    if(Test-RegistryKey "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v3.0\Setup" "InstallSuccess") { "3.0" }
    if(Test-RegistryKey "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v3.5" "Install") { "3.5" }
    if(Test-RegistryKey "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v4\Client" "Install") { "4.0c" }
    if(Test-RegistryKey "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v4\Full" "Install") { "4.0" }        
}
 
function Test-RegistryKey([string]$path, [string]$key){
    if(!(Test-Path $path)) { return $false }
    if ((Get-ItemProperty $path).$key -eq $null) { return $false }
    return $true
}


function Assert-NetFramework {
	[CmdLetBinding()]
	param([Parameter(Position = 1, Mandatory = 0)][string]$Version)
	if($Version -match '[0-9]'){
		$Version = 	$Version + ".0"
	}
	$installedFrameworks = Get-Framework-Versions 
	$matchingFrameworks = $installedFrameworks   | Where { $_ -eq $Version} 
	if (!$matchingFrameworks){
		$message = (".net framework version $Version required (installed versions are {0})" -f [string]::Join(', ',$installedFrameworks))
		throw $message
	}
}


function Install-NetFramwork {
	Import-Module ServerManager
	
	
}


Export-ModuleMember -Function Assert-NetFramework

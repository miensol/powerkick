
function Role {
	param(
		[Parameter(Position=0, Mandatory= 1)]
		[scriptblock]$scriptBlock = {})	
	$powerkick.roles += $scriptBlock	
}

Export-ModuleMember -Function Role
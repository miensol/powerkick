$src = (split-path -parent (Split-Path -Parent $MyInvocation.MyCommand.Path)) + "\src\powerkick"

function Reload-PowerkickModule([string]$moduleName) {
	Import-Module "$src\$($moduleName).psm1" -Force
}

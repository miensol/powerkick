
Role Replicator { 		
	Copy-DirectoryContent 'input' -Destination 'output' -ClearDestination	
}

Role WebApp {
	Write-Host "Deploying web app"
}
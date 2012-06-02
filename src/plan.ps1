
Role Replicator { 		
	Write-Host $settings
	Copy-DirectoryContent 'input' -Destination 'output' -ClearDestination	
}

Role WebApp {
	Write-Host "Deploying web app"
}
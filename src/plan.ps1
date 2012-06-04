
Role Replicator { 		
	Write-Host $settings
	Copy-DirectoryContent 'input' -Destination 'output' -ClearDestination	
} -Rollback {
	Write-Host "Rolling back replicator"
}

Role WebApp {
	Write-Host "Deploying web app"
	throw "Fancy error"
}
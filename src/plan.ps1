
Role Replicator { 	
	param($Settings)		
	Copy-DirectoryContent 'input' -Destination 'output' -ClearDestination	
} -Rollback {
	param($Settings)
	Write-Host "Rolling back replicator"
}

Role WebApp {
	param($Settings)
	Write-Host "Deploying web app"
	throw "Fancy error"
} -Rollback {
	param($Settings)
	
	Write-Host "Successfuly rolled back"
}
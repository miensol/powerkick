
Role Replicator { 	
	param($Settings)		
	Copy-DirectoryContent 'input' -Destination $Settings.ReplicatorPath -ClearDestination	
	Copy-File 'input\file1.txt' $Settings.ReplicatorPath -RenameTo 'renamed.txt'
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
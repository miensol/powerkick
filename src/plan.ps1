
Role Replicator { 	
	param($Settings)	
	$source = 'build\Replicator'
	$binPath =  ("{0}\Replicator.exe" -f $Settings.ReplicatorPath)
	
	Remove-ServiceOnTarget -BinPath $binPath 
	
	Copy-DirectoryContent $source -Destination $Settings.ReplicatorPath -ClearDestination			
	
	New-ServiceOnTarget $binPath -StartAfterCreating
	
} -Rollback {
	param($Settings)
	Write-Host "Rolling back replicator"
}

Role Publisher {
	param($Settings)
	$source = 'build\Publisher\'
	$targetPath = Join-Path $Settings.PublisherPath "Publisher.exe" 
	
	Remove-ServiceOnTarget -BinPath $targetPath 
	
	Copy-DirectoryContent $source -Destination $Settings.PublisherPath -ClearDestination
	
	New-TopshelfServiceOnTarget $targetPath -StartAfterCreating
	
} -Rollback {
	Write-Host "Rolling back publisher"
}


Role WebApp {
	param($Settings)
	
	Invoke-CommandOnTargetServer -Command {
		$log = (Get-Log)
		$log.Info("Hello from remote server") 		
	} 
	
} -Rollback {
	param($Settings)
	
	Write-Host "Successfuly rolled back"
}
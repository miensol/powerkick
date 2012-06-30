
Role Replicator { 	
	param($Settings)	
	$source = 'd:\Users\Piotr\Dropbox\Sources\build\Replicator'
	$binPath =  ("{0}\IHS.Auto.AutoInsight.Replicator.exe" -f $Settings.ReplicatorPath)
	
	Remove-ServiceOnTarget -BinPath $binPath 
	
	Copy-DirectoryContent $source -Destination $Settings.ReplicatorPath -ClearDestination			
	
	New-ServiceOnTarget $binPath -StartAfterCreating
	
} -Rollback {
	param($Settings)
	Write-Host "Rolling back replicator"
}

Role Publisher {
	param($Settings)
	$source = 'd:\Users\Piotr\Dropbox\Sources\build\CsAiPublisher\'
	$targetPath = Join-Path $Settings.PublisherPath "IHS.Auto.AutoInsight.CsAiPublisher.exe" 
	
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
		$log.Debug("Logging message on remote server") 
		throw "remote exception"
	} 
	
} -Rollback {
	param($Settings)
	
	Write-Host "Successfuly rolled back"
}
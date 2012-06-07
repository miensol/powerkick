
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


Role WebApp {
	param($Settings)
	Write-Host "Deploying web app"
	throw "Fancy error"
} -Rollback {
	param($Settings)
	
	Write-Host "Successfuly rolled back"
}
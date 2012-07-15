$local:path = (Split-Path -Parent $MyInvocation.MyCommand.Path)
Import-Module "$local:path\powerkick-log.psm1" 
Import-Module "$local:path\powerkick-helpers.psm1" 

function Connect-ToServer($Server,$Username,$Password){
	$conn = New-Object Microsoft.SqlServer.Management.Common.ServerConnection
	$conn.ServerInstance = $Server
	if($Username -and $Password){
		$conn.LoginSecure = $false
		$conn.Login = $UserName
		$conn.Password = $Password
	}
	New-Object Microsoft.SqlServer.Management.Smo.Server $conn
}


function Load-RequiredAssemblies {
	# TODO: investigate why 'Add-Type -Assembly' fails
	[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.ConnectionInfo');            
	[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Management.Sdk.Sfc');            
	[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO');            
	# Requiered for SQL Server 2008 (SMO 10.0).            
	[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMOExtended');            
	

}

function Backup-SqlServerDatabase {
	[CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=1)][string]$Server,
		[Parameter(Position=2,Mandatory=1)][string]$Database,
		[Parameter(Position=3,Mandatory=1)][string]$BackupFile,
		[Parameter(Position=4,Mandatory=0)][string]$Username,
		[Parameter(Position=5,Mandatory=0)][string]$Password        
    )
	$log = (Get-Log)
	$BackupFile = Get-FullPath $BackupFile
	$log.Info("Backing up $Database from $Server to $BackupFile")
	
	Load-RequiredAssemblies
	
	$srv = Connect-ToServer $Server $Username $Password
	
	$db = $srv.Databases.Item($Database)
	$log.Debug("Connected to server and got database")
	
	$timestamp = Get-Date -format yyyy-MM-dd-HH-mm-ss;     
	$backup = New-Object Microsoft.SqlServer.Management.Smo.Backup            
    $backup.Action = "Database"
    $backup.Database = $db.Name
    $backup.Devices.AddDevice($BackupFile, "File")
    $backup.BackupSetDescription = "Full backup of {0} {1}" -f $db.Name, $timestamp;            
    $backup.Incremental = 0            
    # Starting full backup process.            
    $backup.SqlBackup($srv);     
	$log.Debug("Done backing up database")
	if ($db.RecoveryModel -ne 3){         
		$log.Debug("Will backup log")
        $backup = New-Object Microsoft.SqlServer.Management.Smo.Backup            
        $backup.Action = "Log"            
        $backup.Database = $db.Name            
        $backup.Devices.AddDevice(("{0}.trn" -f $BackupFile), "File")
        $backup.BackupSetDescription = "Log backup of {0} {1}" -f $db.Name, $timestamp
        $backup.LogTruncation = "Truncate"
        $backup.SqlBackup($srv)
		$log.Debug("Done backing up log")
    }      
}

function Restore-SqlServerDatabase {
	[CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=1)][string]$Server,
		[Parameter(Position=2,Mandatory=1)][string]$Database,
		[Parameter(Position=3,Mandatory=1)][string]$BackupFile        
    )
}

Export-ModuleMember -Function Backup-SqlServerDatabase, Restore-SqlServerDatabase
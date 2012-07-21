# Welcome to the powerkick project.

powerkick is a deployment tool for building systematic deployment scripts.

Ideas, names and even some functions come directly from **great project** [Dropkick](https://github.com/chucknorris/dropkick "Dropkick"). 

### Disclaimer
I'm not a powershell guru and am actually learning while writing - any hints and contributions are welcomed.
Note that powerkick is in very early development stage...

## Concepts
The basic idea behing this little gem is to add some structure to deployment scripts that get written. Here is a list of concepts and ideas (that correspond to their originator [Dropkick](https://github.com/chucknorris/dropkick "Dropkick")):
* **Environment** - for example Dev, QA, Prod - a set of machines that you intend to deploy to. Each environment has seperate settings and contains mapping for *Roles* to their target machines.
* **Plan** - actual deployment script, splitted into *Roles* that perform update to each *Environment*
* **Role** - a deployment unit like web application, database or windows service. By default *Roles* are defined in *Plan.ps1* along with their *Rollback* scenarios
* **settings** - there is **only one** deployment plan that gets executed in all environments. We should try hard to make all our environments as equal as possible but some changes, like folder structure, are probably inevitable. That's why for each *Environment* there has to be a file under *settings* directory named *Environment.ps1* with configuration.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
* **ServerMap** - a single *Role*, for example a web application, can be deployed to one or many machines in one *Environment*. The mapping from *Role* to target machines is specified for each *Environment* in file named *Environment-ServerMap.ps1*                                                                   

## Sample
Let's say we want to deploy a web application to iis and install a windows service. To make things more interesting we'll asume that both of them have to be load balanced - so we want them installed on several machines at the same time.

Here's our folder structure:
```
SuperWebApp\
  bin\
  Content\
  Web.config
HyperService\
  Dependency.dll
  Service.exe
powerkick\
settings\
  QA.ps1
  QA-ServerMap.ps1
powerkick.ps1
plan.ps1
```

The `QA.ps1` file contains settings that will be used during deployment to QA:
```powershell
$settings = @{
  SuperWebAppPath = 'c:\apps\SuperWebApp'
  HyperServicePath = 'c:\apps\HyperService'
};
```
The `QA-ServerMap.ps1` file contains mapping of Roles to machines they will get deployed to:
```powershell
$serverMap = @{
  SuperWebApp = @('web-farm-machine-one', 'web-farm-machine-two')
  HyperService = @('service-machine-one', 'service-machine-two')
};
```
As ServerMap indicates the `SuperWebApp` will be deployed to 'web-farm-machine-one' and 'web-farm-machine-two' machines and `HyperService` to 'service-machine-one' and 'service-machine-two'.

The `plan.ps1` file is an actuall script that will deploy our components to target machines using powershell:
```powershell

Role SuperWebApp {
  param($Settings)
  
  Invoke-CommandOnTargetServer {
    param($Name)
    
    Write-NiceMessageToLog
  
    Stop-WebSiteAndAppPool $Name
  
  } -ArgumentList 'SuperWebApp'

  Copy-DirectoryContent ".\SuperWebApp" -Destination $Settings.SuperWebAppPath -ClearDestination
	
  Invoke-CommandOnTargetServer {
    param($Settings)
		
    Initialize-WebAppPool 'SuperWebApp' 'v4.0'
				
    Initialize-Website 'SuperWebApp' -AppPool 'SuperWebApp' -PhysicalPath $Settings.SuperWebAppPath 		
						
			
    Set-AccessRights $Settings.SuperWebAppPath `
      -User "IIS AppPool\SuperWebApp" `
      -Rights "Read, ReadAndExecute, ListDirectory" `
      -AccessType 'Allow' `
      -Inheritance 'ContainerInherit' `
      -Propagation 'InheritOnly'

    Start-WebSiteAndAppPool 'SuperWebApp'	
  } -ArgumentList $Settings							
}

Role HyperService {
  param($Settings)
  
  Write-NiceMessageToLog
  
  Remove-ServiceOnTarget 'HyperService'
  
  Copy-DirectoryContent ".\HyperService" -Destination $Settings.HyperServicePath -ClearDestination
 
  New-ServiceOnTarget "$($Settings.HyperServicePath)\HyperService.exe"
} -Rollback {
  (Get-Log).Error("Something went wrong - will try to rollback...")
}

Helpers {
  function Write-NiceMessageToLog {
  	(Get-Log).Info("Hello from $($env:COMPUTERNAME)")
  }

}

```

To deploy all Roles to QA environment simply invoke following command from powershell (as Administrator):
`.\powerkick.ps1 -Environment QA`

The above command will do the following:
- Deploy SuperWebApp to 'web-farm-machine-one' and 'web-farm-machine-two' by:
  - Stopping IIS application pool and Web Site called SuperWebApp
  - Copying SuperWebApp contents to path specified in settings on remote machine
  - Making sure that there is is a SuperWebApp app pool on iis with .net framework version set to 4
  - Making sure that there is a SuperWebApp web site in iis with path and app pool properly set
  - Giving required file system rights to a app pool process identity
  - Starting iis application pool and web site called SuperWebApp
- Deploy HyperService to 'service-machine-one' and 'service-machine-two' by:
  - Stoping and removing any existing service called HyperService
  - Copying HyperService directory contents to path specified in settings on remote machine
  - Creating and starting new windows service called HyperService

**powerkick** will deploy each role on each target server using the same script block passed in `Role $RoleName {}`
For commands that require execution on remote machine there is a `Invoke-CommandOnTargetServer` function that will try to establish powershell session to that machine under the covers.
A log file for each deployment run will be created next to `plan.ps1` file inside deployment-log directory.

To verify what will happen during a deployment of SuperWebApp pass -WhatIf switch to powerkick:
`.\powerkick.ps1 -Role SuperWebApp -Environment QA -WhatIf`
No changes to target systems will be made.

If you deploy several similar components you can remove duplication from your deployment script by defining helper functions inside `Helpers` (take a look at `Write-NiceMessageToLog` from sample).





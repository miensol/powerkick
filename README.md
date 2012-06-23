# Welcome to the powerkick project.

powerkick is a deployment tool for building systematic deployment scripts
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


$src = (split-path -parent (Split-Path -Parent $MyInvocation.MyCommand.Path)) + "\src\powerkick"
Remove-Module 'powerkick-*' | Out-Null
Import-Module "$src\powerkick-files.psm1" | Out-Null		

Describe "mapping local path to remote server" {	
	It "should properly map absolute path" {		
		$mappedPath = Convert-PathToPhysical "c:\Windows" "remote-machine"
		$mappedPath.should.be("\\remote-machine\c$\Windows")
	}
	
	It "should properly map path with admin share specified" {
		$mappedPath = Convert-PathToPhysical "\\remote-machine\c$\Windows" "remote-machine"
		$mappedPath.should.be("\\remote-machine\c$\Windows")
	}
	
	It "should properly map path with admin share specified with colon" {
		$mappedPath = Convert-PathToPhysical "\\remote-machine\c:\Windows" "remote-machine"
		$mappedPath.should.be("\\remote-machine\c$\Windows")
	}
}

Describe "mapping local path to local server" {
	It "should properly map absolute path" {
		$mappedPath = Convert-PathToPhysical "c:\Windows" "localhost"
		$mappedPath.should.be("c:\Windows")
	}
	
	it "should properly map share to local path" {
		$mappedPath = Convert-PathToPhysical "\\localhost\c$\Windows" "localhost"
		$mappedPath.should.be("c:\Windows")	
	}
	
	Describe "mapping path with share name to local path but share does not exist" {
		it "should throw an excpetion with share name in message" {
			try {
				$mappedPath = Convert-PathToPhysical "\\localhost\notexistingshare\Windows" "localhost"
				$mappedPath.should.be("exceptio should be thrown")
			}catch {				
				($_.ToString() -match "notexistingshare").should.be($true)
			}
		}
	}
}
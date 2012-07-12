Get-ChildItem **\spec-helpers.ps1 | ForEach { . $_.FullName }

Reload-PowerkickModule powerkick-helpers


Describe 'tests for local server' {
	
	It 'be true for localhost' {
		(Test-IsLocal localhost).should.be($true)
	}
	
	It 'be true for local machine name' {
		(Test-IsLocal $Env:COMPUTERNAME).should.be($true)
	}
	
	It 'be false for remote machine' {
		(Test-IsLocal google.com).should.be($false)
	}
	

}
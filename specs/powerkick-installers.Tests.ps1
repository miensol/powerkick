Get-ChildItem **\spec-helpers.ps1 | ForEach { . $_.FullName }

Reload-PowerkickModule 'powerkick-installers'

Describe 'Require specify .net version' {
	
	It 'should throw framework is not avialable' {		
		try {
			Assert-NetFramework -Version 5
			"should throw exception already".should.be("")
		}catch {
			$_.should.match('.net framework version 5.0 required')
		}			
	}
	
	it 'should not throw when framework is available' {
		Assert-NetFramework -Version 4
	}		
}
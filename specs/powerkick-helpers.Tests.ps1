$src = (split-path -parent (Split-Path -Parent $MyInvocation.MyCommand.Path)) + "\src\powerkick"

Import-Module "$src\powerkick-helpers.psm1" -Force

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
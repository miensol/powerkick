Get-ChildItem **\spec-helpers.ps1 | ForEach { . $_.FullName }

function ReloadModule {
	Reload-PowerkickModule "powerkick-log"
}

Describe "getting log file" {	
	
	It "by default it should return file in current directory" {				
		ReloadModule 
		(Get-LogFile).should.be("$(pwd)\log.txt")
	}			
	
	It "should allow setting file name externaly" {
		ReloadModule 
		(Set-LogFileName "newlogname")
		(Get-LogFile).should.be("$(pwd)\newlogname")
	}
	
	it "should properly set file name from current time and machie name" {
		ReloadModule 
		$dateTime = [System.DateTime]::Now;
		Set-LogFileNameFromCurrentTime "$(pwd)\logs"
		$logName = (Get-LogFile)
		$direcotry  = (Split-Path -Parent $logName)
		$fileName = (Split-Path -Leaf $logName)
		$direcotry.should.be("$(pwd)\logs")
		$fileName.should.match("powerkick-log")
		$fileName.should.match($dateTime.Year)
		$fileName.should.match($dateTime.Month)
		$fileName.should.match($dateTime.Day)
		$fileName.should.match($dateTime.Hour)
		$fileName.should.match($dateTime.Minute)
		$fileName.should.match($Env:COMPUTERNAME)
	}
}

Describe "getting transcript file" {
	
	It "by default should return file in current directory" {
		ReloadModule 
		(Get-TranscriptLogFile).should.be("$(pwd)\log-transcript.txt")
	}
	
	It "should properly set file name from current date time " {
		ReloadModule 
		$dateTime = [System.DateTime]::Now;
		Set-LogFileNameFromCurrentTime "$(pwd)\logs"
		$logName = (Get-TranscriptLogFile)
		$direcotry  = (Split-Path -Parent $logName)
		$fileName = (Split-Path -Leaf $logName)
		$logName.should.match("powerkick-log-transcript")
		
	}
}


Describe "logging" {
	
	Setup -File "log.txt" ""
	In $TestDrive {
		ReloadModule 
	}
	
	It "should properly log info" {
		(Get-Log).Info("information")
		(Get-Content "$TestDrive\log.txt").should.match("information")
	}
	
	It "should properly log warning" {
		(Get-Log).Warning("warningmessage")
		(Get-Content "$TestDrive\log.txt").should.match("warningmessage")
	}
	
	It "should properly log error" {
		(Get-Log).Error("errormessage")
		(Get-Content "$TestDrive\log.txt").should.match("errormessage")
	}		

}


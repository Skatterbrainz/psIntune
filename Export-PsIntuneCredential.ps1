function Export-PsIntuneCredential {
	[CmdletBinding()]
	param (
		[parameter(Mandatory)][ValidateNotNullOrEmpty()][string] $OutputFile,
		[parameter()][pscredential] $Credential
	)
	try {
		if ($null -eq $Credential) {
			$Credential = Get-Credential
		}
		if ($null -ne $Credential) {
			Write-Verbose "saving credentials to $OutputFile"
			$Credential | Export-Clixml $OutputFile -Force
			Write-Host "credentials saved to: $OutputFile"
		}
	}
	catch {
		Write-Error $_.Exception.Message 
	}
}
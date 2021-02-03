<#
.SYNOPSIS
	Save PS Credential object to encoded XML file
.DESCRIPTION
	Save PS Credential object to encoded XML file
.PARAMETER OutputFile
	Path to XML file
.PARAMETER Credential
	Optional PS crecential object. If not provided, GUI prompt is provided
.EXAMPLE
	Export-PsIntuneCredential -OutputPath ".\cred_contoso_azure.xml"
.EXAMPLE
	Export-PsIntuneCredential -OutputPath ".\cred_contoso_azure.xml" -Credential $mycred
.LINK
	https://github.com/Skatterbrainz/psintune/blob/master/docs/Export-PsIntuneCredential.md
#>
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
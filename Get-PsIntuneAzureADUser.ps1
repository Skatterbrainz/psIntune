function Get-psIntuneAzureADUser() {
	<#
	.SYNOPSIS
		This function is used to get AAD Users from the Graph API REST interface
	.DESCRIPTION
		The function connects to the Graph API Interface and gets any users registered with AAD
	.EXAMPLE
		Get-psIntuneAzureADUser
		Returns all users registered with Azure AD
	.EXAMPLE
		Get-psIntuneAzureADUser -userPrincipleName user@domain.com
		Returns specific user by UserPrincipalName registered with Azure AD
	.NOTES
		NAME: Get-psIntuneAzureADUser
	.LINK
		https://github.com/Skatterbrainz/psintune/blob/master/docs/Get-psIntuneAzureADUser.md
	#>
	[CmdletBinding()]
	param (
		[parameter()][string] $UserPrincipalName,
		[parameter()][string] $Property
	)
	$User_resource = "users"

	try {
		if ([string]::IsNullOrEmpty($UserPrincipalName)) {
			$uri = "https://graph.microsoft.com/$graphApiVersion/$($User_resource)"
			(Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
		}
		else {
			if ([string]::IsNullOrEmpty($Property)) {
				$uri = "https://graph.microsoft.com/$graphApiVersion/$($User_resource)/$UserPrincipalName"
				Write-Verbose $uri
				Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get
			}
			else {
				$uri = "https://graph.microsoft.com/$graphApiVersion/$($User_resource)/$UserPrincipalName/$Property"
				Write-Verbose $uri
				(Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
			}
		}
	}
	catch {
		$ex = $_.Exception
		$errorResponse = $ex.Response.GetResponseStream()
		$reader = New-Object System.IO.StreamReader($errorResponse)
		$reader.BaseStream.Position = 0
		$reader.DiscardBufferedData()
		$responseBody = $reader.ReadToEnd();
		Write-Host "Response content:`n$responseBody" -f Red
		Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
		break
	}
}

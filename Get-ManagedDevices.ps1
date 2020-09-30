function Get-ManagedDevices(){
	<#
	.SYNOPSIS
		This function is used to get Intune Managed Devices from the Graph API REST interface

	.DESCRIPTION
		The function connects to the Graph API Interface and gets any Intune Managed Device

	.PARAMETER IncludeEAS
		Switch to include EAS devices (not included by default)

	.PARAMETER ExcludeMDM
		Switch to exclude MDM devices (not excluded by default)

	.PARAMETER DeviceOS
		Filter devices by operating system. Options: Android, iOS, Windows, All
		Default is All

	.EXAMPLE
		Get-ManagedDevices

		Returns all managed devices but excludes EAS devices registered within the Intune Service

	.EXAMPLE
		Get-ManagedDevices -IncludeEAS

		Returns all managed devices including EAS devices registered within the Intune Service

	.NOTES
		NAME: Get-ManagedDevices

	.LINK
		https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-ManagedDevices.md
	#>
	[cmdletbinding()]
	param (
		[parameter(Mandatory)][string] $UserName,
		[parameter()][string] $DeviceName = "",
		[parameter()][string][ValidateSet('All','Windows','Android','iOS')] $DeviceOS = 'All',
		[parameter()][switch] $IncludeEAS,
		[parameter()][switch] $ExcludeMDM,
		[parameter()][string] $graphApiVersion = "beta"
	)
	$Resource = "deviceManagement/managedDevices"
	try {
		Get-psIntuneAuth -UserName $UserName
		$Count_Params = 0
		if ($IncludeEAS.IsPresent){ $Count_Params++ }
		if ($ExcludeMDM.IsPresent){ $Count_Params++ }
		if ($Count_Params -gt 1) {
			Write-Warning "Multiple parameters set, specify a single parameter -IncludeEAS, -ExcludeMDM or no parameter against the function"
			break
		}
		elseif ($IncludeEAS) {
			Write-Verbose "IncludeEAS = true"
			$uri = "https://graph.microsoft.com/$graphApiVersion/$Resource"
		}
		elseif ($ExcludeMDM) {
			Write-Verbose "ExcludeMDM = true"
			$uri = "https://graph.microsoft.com/$graphApiVersion/$Resource`?`$filter=managementAgent eq 'eas'"
		}
		else {
			if (![string]::IsNullOrEmpty($DeviceName)) {
				Write-Verbose "DeviceName = $DeviceName"
				$uri = "https://graph.microsoft.com/$graphApiVersion/$Resource`?`$filter=deviceName eq '$DeviceName' and managementAgent eq 'mdm' and managementAgent eq 'easmdm'"
			}
			else {
				Write-Verbose "Default = True"
				$uri = "https://graph.microsoft.com/$graphApiVersion/$Resource`?`$filter=managementAgent eq 'mdm' and managementAgent eq 'easmdm'"
				if ($DeviceOS -ne 'All') {
					$uri += " and operatingSystem eq '$DeviceOS'"
				}
			}
			Write-Warning "EAS Devices are excluded by default, please use -IncludeEAS if you want to include those devices"
		}
		Write-Verbose "uri = $uri"
		$response = (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get)
		$Devices = $response.Value
		$DevicesNextLink = $response."@odata.nextLink"
		while ($DevicesNextLink) {
			$response = (Invoke-RestMethod -Uri $DevicesNextLink -Headers $authToken -Method Get)
			$DevicesNextLink = $response."@odata.nextLink"
			$Devices += $response.value 
		}
		$Devices
	}
	catch {
		$ex = $_.Exception
		$errorResponse = $ex.Response.GetResponseStream()
		$reader = New-Object System.IO.StreamReader($errorResponse)
		$reader.BaseStream.Position = 0
		$reader.DiscardBufferedData()
		$responseBody = $reader.ReadToEnd();
		Write-Warning "Response content:`n$responseBody"
		Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
		break
	}
}
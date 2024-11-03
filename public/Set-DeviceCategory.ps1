function Set-DeviceCategory {
	<#
	.SYNOPSIS
		Set the device category for a device
	.DESCRIPTION
		Set the device category for a device in Intune
	.PARAMETER DeviceID
		Device ID of the device to update
	.PARAMETER CategoryID
		Category ID to assign to the device
	.PARAMETER BaseUrl
		Base URL for the Intune Graph API. Example: https://graph.microsoft.com/beta
	.EXAMPLE
		Set-DeviceCategory -DeviceID "12345678-1234-1234-1234-123456789012" -CategoryID "12345678-1234-1234-1234-123456789012" -BaseUrl "https://graph.microsoft.com/beta"
		Set the device category for the device with ID 12345678-1234-1234-1234-123456789012 to the category with ID 12345678-1234-1234-1234-123456789012
	.LINK
		https://github.com/Skatterbrainz/psintune/blob/master/docs/Set-DeviceCategory.md
	#>
	[CmdletBinding(SupportsShouldProcess=$True)]
	param (
		[parameter(Mandatory)][string] $DeviceID,
		[parameter(Mandatory)][string] $CategoryID,
		[parameter(Mandatory)][string] $BaseUrl
	)
	Write-Verbose "updating device... $DeviceID"
	$requestBody = @{
		"@odata.id" = "$baseUrl/deviceManagement/deviceCategories/$CategoryID"
	}
	[string]$url = "$baseUrl/deviceManagement/managedDevices/$DeviceID/deviceCategory/`$ref"
	Write-Verbose "request-url: $url"
	if (!$WhatIfPreference) {
		$result = Invoke-MSGraphRequest -HttpMethod PUT -Url $url -Content $requestBody
	} else {
		Write-Host "[WHAT-IF] would submit request to graph API" -ForegroundColor Cyan
	}
	#$result
	Update-MgUserManagedDeviceCategory -DeviceID $DeviceID -CategoryID $CategoryID
	Update-MgManagedDeviceDeviceCategory -DeviceID $DeviceID -CategoryID $CategoryID
}

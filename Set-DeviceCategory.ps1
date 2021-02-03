function Set-DeviceCategory {
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
}

function Get-psIntuneDevicesWithApp {
	<#
	.SYNOPSIS
		Returns Intune managed devices having a specified App installed

	.DESCRIPTION
		Returns Intune managed devices having a specified App installed

	.PARAMETER AppDataSet
		Applications dataset returned from Get-DsIntuneDeviceApps().
		If not provided, Devices are queried automatically, which will incur additional time.

	.PARAMETER Application
		Name, or wildcard name, of App to search for

	.PARAMETER UserName
		UserPrincipalName for authentication request

	.PARAMETER ShowProgress
		Display progress during execution (default is silent / no progress shown)

	.EXAMPLE
		Get-psIntuneDevicesWithApp -Application "*Putty*" -UserName "john.doe@contoso.com"

		Returns list of Intune-managed devices which have any app name containing "Putty" installed

	.EXAMPLE
		Get-psIntuneDevicesWithApp -Application "*Putty*" -UserName "john.doe@contoso.com" -ShowProgress

		Returns list of Intune-managed devices which have any apps name containing "Putty" installed, and displays progress during execution

	.NOTES
		NAME: Get-psIntuneDevicesWithApp
		This function was derived almost entirely from https://www.dowst.dev/search-intune-for-devices-with-application-installed/
		(Thanks to Matt Dowst!)

	.LINK
		https://github.com/Skatterbrainz/psintune/blob/master/docs/Get-psIntuneDevicesWithApp.md

	#>
	[CmdletBinding()]
	param (
		[parameter()] $AppDataSet,
		[parameter(Mandatory)][ValidateNotNullOrEmpty()][string] $Application,
		[parameter()][string] $Version,
		[parameter(Mandatory)][ValidateNotNullOrEmpty()][string] $Username,
		[parameter()][boolean] $ShowProgress = $False
	)
	Write-Verbose "Getting authentication token"
	$AuthHeader = Get-AuthToken -User $Username

	Write-Verbose "getting all devices in Intune"
	$AllDevices = Get-MsGraphData "deviceManagement/managedDevices"

	# Get detected app for each device and check for app name
	[System.Collections.Generic.List[PSObject]]$FoundApp = @()
	$wp = 1
	Write-Verbose "querying devices for $Application $Version"
	foreach ($Device in $AllDevices) {
		if ($ShowProgress) { Write-Progress -Activity "Found $($FoundApp.count)" -Status "$wp of $($AllDevices.count)" -PercentComplete $(($wp/$($AllDevices.count))*100) -id 1 }
		$AppData = Get-MsGraphData "deviceManagement/managedDevices/$($Device.id)?`$expand=detectedApps"
		$DetectedApp = $AppData.detectedApps | Where-Object {$_.displayname -like $Application}
		if (![string]::IsNullOrEmpty($Version)) {
			$DetectedApp = $DetectedApp | Where-Object { $_.ProductVersion -eq $Version }
		}
		if ($null -ne $DetectedApp) {
			$DetectedApp | 
				Select-Object @{l='DeviceName';e={$Device.DeviceName}}, @{l='Application';e={$_.displayname}}, Version, SizeInByte,
				@{l='LastSyncDateTime';e={$Device.lastSyncDateTime}}, @{l='DeviceId';e={$Device.id}} | 
					Foreach-Object { $FoundApp.Add($_) }
		}
		$wp++
	}
	if ($ShowProgress -eq $True) { Write-Progress -Activity "Done" -Id 1 -Completed }
	$FoundApp
}
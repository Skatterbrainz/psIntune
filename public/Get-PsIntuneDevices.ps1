function Get-PsIntuneDevices {
	<#
	.SYNOPSIS
		This function is used to get a list of Intune Devices
	.DESCRIPTION
		The function connects to the Graph API Interface and gets a list of Intune Devices
	.PARAMETER Refresh
		Refresh the list of devices
	.EXAMPLE
		Get-PsIntuneDevices
		Returns a list of Intune Devices
	.EXAMPLE
		Get-PsIntuneDevices -Refresh
		Refreshes the list of Intune Devices
	.LINK
		https://github.com/Skatterbrainz/psintune/blob/master/docs/Get-PsIntuneDevices.md
	#>
	[CmdletBinding()]
	param(
		[parameter()][switch]$Refresh
	)
	try {
		if (!$intuneDevices -or $Refresh.IsPresent) {
			$global:intuneDevices = Get-MgDeviceManagementManagedDevice -All:$true
		}
		$intuneDevices
	} catch {
		Write-Error $_.Exception.Message
	}
}
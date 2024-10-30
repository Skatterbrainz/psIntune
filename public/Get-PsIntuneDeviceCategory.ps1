function Get-PsIntuneDeviceCategory {
	[CmdletBinding()]
	param(
		[parameter(Mandatory=$false)][string]$CategoryId
	)
	if (![string]::IsNullOrEmpty($CategoryId)) {
		Get-MgDeviceManagementDeviceCategory -DeviceCategoryId $CategoryId
	} else {
		Get-MgDeviceManagementDeviceCategory -All:$true
	}
}
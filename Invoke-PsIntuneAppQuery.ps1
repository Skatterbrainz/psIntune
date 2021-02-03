function Invoke-psIntuneAppQuery {
	<#
	.SYNOPSIS
		Query DataSet for unique App installation counts

	.DESCRIPTION
		Filters instances of application installations by Name/Title only to determine
		unique installations by device.  Some devices will report multiple instances of 
		the same application, with different ProductVersion numbers. This function excludes
		duplicates to show one-per-device only.

	.PARAMETER AppDataSet
		Device data returned from Get-DsIntuneDeviceData(). If not provided, Get-DsIntuneDeviceData() is invoked automatically.
		Passing Device data to -DeviceData can save significant processing time.

	.PARAMETER ProductName
		Application Product name

	.EXAMPLE
		$devices = Get-DsIntuneDeviceData -UserName "john.doe@contoso.com"
		$applist = Get-DsIntuneDeviceApps -DataSet $devices
		$rows = Invoke-psIntuneAppQuery -AppDataSet $applist -ProductName "Acme Crapware 19.20 64-bit"

	.NOTES
		NAME: Invoke-psIntuneAppQuery

	.LINK
		https://github.com/Skatterbrainz/psintune/blob/master/docs/Invoke-psIntuneAppQuery.md

	#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory)][ValidateNotNullOrEmpty()] $AppDataSet,
		[parameter(Mandatory)][ValidateNotNullOrEmpty()][string] $ProductName
	)
	try {
		$result = ($AppDataSet | Select-Object ProductName,DeviceName | Where-Object {$_.ProductName -eq $ProductName} | Sort-Object ProductName,DeviceName -Unique)
	}
	catch {
		Write-Error $_.Exception.Message
	}
	finally {
		$result
	}
}
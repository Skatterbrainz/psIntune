function Get-PsIntuneEntraDeviceSummary {
	<#
	.SYNOPSIS
		This function is used to get a summary of Entra Devices
	.DESCRIPTION
		The function connects to the Graph API Interface and gets a summary of Entra Devices based on the specified grouping
	.PARAMETER EntraDevices
		Entra Devices to summarize. This should be the output from Get-PsIntuneEntraDevices
	.PARAMETER GroupBy
		Property to group by. Options: OS, DeviceCategory, DeviceOwnership, ManagementType, EnrollmentType, Manufacturer, Model, Active
		Default is OS
	.PARAMETER DeviceOS
		Filter devices by operating system. Options: All, Windows, Android, iOS, Windows Server, IPhone, Unknown, AndroidForWork
		Default is All
	.EXAMPLE
		Get-PsIntuneEntraDeviceSummary -EntraDevices $entraDevices -GroupBy OS
		Returns a summary of Entra Devices grouped by Operating System
	#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$true)]$EntraDevices,
		[parameter()][string][ValidateSet('OS','DeviceCategory','DeviceOwnership','ManagementType','EnrollmentType','Manufacturer','Model','Active')]$GroupBy = 'OS',
		[parameter()][string][ValidateSet('All','Windows','Android','iOS','Windows Server','IPhone','Unknown','AndroidForWork')]$DeviceOS = 'All'
	)
	switch ($GroupBy) {
		'OS'              { $prop = 'OperatingSystem' }
		'DeviceCategory'  { $prop = 'DeviceCategory' }
		'DeviceOwnership' { $prop = 'DeviceOwnership' }
		'ManagementType'  { $prop = 'ManagementType' }
		'EnrollmentType'  { $prop = 'EnrollmentType' }
		'Manufacturer'    { $prop = 'Manufacturer' }
		'Model'           { $prop = 'Model' }
		'Active'          { $prop = 'AccountEnabled' }
	}
	if ($DeviceOS -eq 'All') {
		$EntraDevices | Group-Object -Property $prop | Select-Object Name, Count | Sort-Object Count -Descending
	} else {
		$EntraDevices | Where-Object { $_.OperatingSystem -eq $DeviceOS } |
			Group-Object -Property $prop | Select-Object Name, Count | Sort-Object Count -Descending
	}
}
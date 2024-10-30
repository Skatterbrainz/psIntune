function Get-PsIntuneDeviceSummary {
	[CmdletBinding()]
	param(
		[parameter(Mandatory=$true)]$IntuneDevices,
		[parameter()][string][ValidateSet('OS','DeviceCategory','Ownership','Category','EnrollmentType','Manufacturer','Model','Encrypted','ComplianceState')]$GroupBy = 'OS',
		[parameter()][string][ValidateSet('All','Windows','Android','iOS','Windows Server','IPhone','Unknown','AndroidForWork')]$DeviceOS = 'All'
	)
	switch ($GroupBy) {
		'OS'              { $prop = 'OperatingSystem' }
		'Ownership'       { $prop = 'ManagedDeviceOwnerType' }
		'Category'        { $prop = 'DeviceCategoryDisplayName' }
		'EnrollmentType'  { $prop = 'DeviceEnrollmentType' }
		'Manufacturer'    { $prop = 'Manufacturer' }
		'Model'           { $prop = 'Model' }
		'Compliance'      { $prop = 'ComplianceState' }
		'Encrypted'       { $prop = 'IsEncrypted' }
	}
	$IntuneDevices | Group-Object -Property $prop | Select-Object Name, Count | Sort-Object Count -Descending
}
function Get-psIntuneDevice {
	<#
	.SYNOPSIS
		Returns dataset of Intune-managed devices with inventoried apps
	.DESCRIPTION
		Returns dataset of Intune-managed devices with inventoried apps
	.PARAMETER UserName
		UserPrincipalName for authentication request
	.PARAMETER DeviceName
		Filter query to just one specified device by name. Default is query all devices
	.PARAMETER DeviceOS
		Filter devices by operating system. Options: Android, iOS, Windows, All
		Default is All
	.PARAMETER ShowProgress
		Display progress as data is exported (default is silent / no progress shown)
	.PARAMETER Detail
		Controls the level of granularity of the results:
		* Summary - returns basic device information only
		* Detailed - returns detailed device information
		* Full - returns detailed device information with installed applications
		* Raw - returns raw Graph API results only
	.PARAMETER graphApiVersion
		Graph API version. Default is "beta"
	.EXAMPLE
		$devices = Get-psIntuneDevice -UserName "john.doe@contoso.com" -DeviceName "Desktop123" -Detail Detailed
		Returns detailed data for one device without installed applications
	.EXAMPLE
		$devices = Get-psIntuneDevice -UserName "john.doe@contoso.com" -DeviceOS Windows -Detail Detailed
		Returns detailed data for Windows devices without applications
	.EXAMPLE
		$devices = Get-psIntuneDevice -UserName "john.doe@contoso.com"
		Returns summary data without applications
	.EXAMPLE
		$devices = Get-psIntuneDevice -UserName "john.doe@contoso.com" -ShowProgress
		Returns summary data without applications and shows progress during processing
	.EXAMPLE
		$devices = Get-psIntuneDevice -UserName "john.doe@contoso.com" -Detail -Full -ShowProgress
		Returns detailed data with applications for each device and shows progress during processing
	.NOTES
		NAME: Get-psIntuneDevice
	.LINK
		https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-psIntuneDevice.md
	#>
	[CmdletBinding()]
	[OutputType([hashtable])]
	param (
		[parameter()][string] $UserName = $($global:psintuneuser),
		[parameter()][string] $DeviceName = "",
		[parameter()][ValidateSet('Full','Detailed','Summary','Raw')][string] $Detail = 'Summary',
		[parameter()][string][ValidateSet('All','Windows','Android','iOS')] $DeviceOS = 'All',
		[parameter()][boolean] $ShowProgress = $False,
		[parameter()][string] $graphApiVersion = "beta"
	)
	if ([string]::IsNullOrEmpty($UserName)) { throw "UserName was not provided" }
	$global:psintuneuser = $UserName
	try {
		if (![string]::IsNullOrEmpty($DeviceName)) {
			$devices = Get-ManagedDevices -Username $UserName -DeviceName $DeviceName
		}
		else {
			if ($DeviceOS -ne 'All') {
				$devices = Get-ManagedDevices -UserName $UserName -DeviceOS $DeviceOS
			}
			else {
				$devices = Get-ManagedDevices -UserName $UserName
			}
		}
		$dcount = $Devices.Count
		$dx = 1
		Write-Verbose "returned $dcount Intune managed devices"
		if ($Detail -eq 'Full') {
			Write-Warning "Full option takes the longest to process. This may take a few minutes."
		}
		foreach ($Device in $Devices){
			if ($ShowProgress -eq $True) { 
				Write-Progress -Activity "Found $dcount Intune managed devices" -Status "Reading device $dx of $dcount" -PercentComplete $(($dx/$dcount)*100) -id 1
			}
			$DeviceID = $Device.id
			$LastSync = $Device.lastSyncDateTime
			$SyncDays = (New-TimeSpan -Start $LastSync -End (Get-Date)).Days
			switch ($Detail) {
				'Summary' {
					$upn = $Device.userPrincipalName
					if (![string]::IsNullOrEmpty($upn)) {
						$dom = $($upn -split '@')[1]
					} else {
						$dom = ""
					}
					[pscustomobject]@{
						DeviceName   = $Device.DeviceName
						DeviceID     = $DeviceID
						UserName     = $Device.userDisplayName
						Domain       = $dom
						OSName       = $Device.operatingSystem 
						OSVersion    = $Device.osVersion
						LastSyncTime = $LastSync
						LastSyncDays = $SyncDays
					}	
				}
				'Detailed' {
					$compliant = $($Device.complianceState -eq $True)
					$disksize  = [math]::Round(($Device.totalStorageSpaceInBytes / 1GB),2)
					$freespace = [math]::Round(($Device.freeStorageSpaceInBytes / 1GB),2)
					$mem       = [math]::Round(($Device.physicalMemoryInBytes / 1GB),2)
					$upn       = $Device.userPrincipalName
					if (![string]::IsNullOrEmpty($upn)) {
						$dom = $($upn -split '@')[1]
					} else {
						$dom = ""
					}
					[pscustomobject]@{
						DeviceName   = $Device.DeviceName
						DeviceID     = $DeviceID
						Manufacturer = $Device.manufacturer
						Model        = $Device.model 
						UserName     = $Device.userDisplayName
						UserEmail    = $Device.emailAddress
						UserUPN      = $upn
						Domain       = $dom
						ManageState  = $Device.managementState
						Encrypted    = $Device.isEncrypted
						Registration = $Device.deviceRegistrationState
						Enrollment   = $Device.deviceEnrollmentType
						AzureADDevID = $Device.azureADDeviceId
						AutoPilot    = $Device.autopilotEnrolled
						EthernetMAC  = $Device.ethernetMacAddress
						WiFiMAC      = $Device.WiFiMacAddress
						MemoryGB     = $mem
						DiskSizeGB   = $disksize
						FreeSpaceGB  = $freespace
						SerialNumber = $Device.serialNumber 
						OSName       = $Device.operatingSystem 
						OSVersion    = $Device.osVersion
						Ownership    = $Device.ownerType
						Category     = $Device.deviceCategoryDisplayName
						EnrollDate   = $Device.enrolledDateTime
						ManagedBy    = $Device.managementAgent
						LastSyncTime = $LastSync
						LastSyncDays = $SyncDays
						Compliant    = $compliant
					}	
				}
				'Full' {
					#Start-Sleep -Seconds 1
					$uriApps = "https://graph.microsoft.com/$graphApiVersion/deviceManagement/manageddevices('$DeviceID')?`$expand=detectedApps"
					$DetectedApps = (Invoke-RestMethod -Uri $uriApps -Headers $authToken -Method Get).detectedApps
					$compliant = $($Device.complianceState -eq $True)
					$disksize  = [math]::Round(($Device.totalStorageSpaceInBytes / 1GB),2)
					$freespace = [math]::Round(($Device.freeStorageSpaceInBytes / 1GB),2)
					$mem       = [math]::Round(($Device.physicalMemoryInBytes / 1GB),2)
					$upn       = $Device.userPrincipalName
					if (![string]::IsNullOrEmpty($upn)) {
						$dom = $($upn -split '@')[1]
					} else {
						$dom = ""
					}
					[pscustomobject]@{
						DeviceName   = $Device.DeviceName
						DeviceID     = $DeviceID
						Manufacturer = $Device.manufacturer
						Model        = $Device.model 
						UserName     = $Device.userDisplayName
						UserEmail    = $Device.emailAddress
						UserUPN      = $upn
						Domain       = $dom
						ManageState  = $Device.managementState
						Encrypted    = $Device.isEncrypted
						Registration = $Device.deviceRegistrationState
						Enrollment   = $Device.deviceEnrollmentType
						AzureADDevID = $Device.azureADDeviceId
						AutoPilot    = $Device.autopilotEnrolled
						EthernetMAC  = $Device.ethernetMacAddress
						WiFiMAC      = $Device.WiFiMacAddress
						MemoryGB     = $mem
						DiskSizeGB   = $disksize
						FreeSpaceGB  = $freespace
						SerialNumber = $Device.serialNumber 
						OSName       = $Device.operatingSystem 
						OSVersion    = $Device.osVersion
						Ownership    = $Device.ownerType
						Category     = $Device.deviceCategoryDisplayName
						EnrollDate   = $Device.enrolledDateTime
						ManagedBy    = $Device.managementAgent
						LastSyncTime = $LastSync
						LastSyncDays = $SyncDays
						Compliant    = $compliant
						Apps         = $DetectedApps
					}	
				}
				'Raw' {
					$Device
				}
			} # switch
			$dx++
		} # foreach
	}
	catch {
		Write-Warning "Queried $dx of $dcount Intune devices before encountering an error"
		Write-Error $_.Exception.Message 
	}
}

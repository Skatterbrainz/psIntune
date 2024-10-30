function Get-PsIntuneEntraDevices {
	<#
	.SYNOPSIS
		This function is used to get Entra Devices from the Graph API REST interface
	.DESCRIPTION
		The function connects to the Graph API Interface and gets any devices registered with EntraID
	.PARAMETER ShowProgress
		Display progress as data is exported (default is silent / no progress shown)
	.PARAMETER Refresh
		Force a refresh of the data
	.EXAMPLE
		$entraDevices = Get-PsIntuneEntraDevices
		Returns all devices registered with Entra
	.EXAMPLE
		$entraDevices = Get-PsIntuneEntraDevices -ShowProgress
		Returns all devices registered with Entra and shows progress during processing
	.EXAMPLE
		$entraDevices = Get-PsIntuneEntraDevices -Refresh
		Forces a refresh of the data
	.LINK
		https://github.com/Skatterbrainz/psintune/blob/master/docs/Get-PsIntuneEntraDevices.md
	#>
	[CmdletBinding()]
	param(
		[parameter()][switch]$ShowProgress,
		[parameter()][switch]$Refresh
	)
	try {
		if ($entraDevices -and !$Refresh.IsPresent) {
			$entraDevices
		} else {
			$edevices = Get-MgDevice -All:$True -ConsistencyLevel Eventual
			if ($edevices.Count -gt 0) {
				$result = @()
				$total = $edevices.Count
				$index = 1
				foreach ($device in $entraDevices) {
					if ($ShowProgress) {
						Write-Progress -Activity "Analyzing $total Entra devices" -Status "Reading device $index of $total : $($device.DisplayName)" -PercentComplete ($index / $total * 100) -id 1
					}
					$owner = $null
					$owner = Get-MgDeviceRegisteredOwnerAsUser -DeviceId $device.Id #| Select-Object -ExpandProperty UserPrincipalName
					if (![string]::IsNullOrEmpty($device.ApproximateLastSignInDateTime)) {
						$xdaysOld = (New-TimeSpan -Start $(Get-Date $device.ApproximateLastSignInDateTime) -End (Get-Date)).Days
					} else {
						$xdaysOld = $null
					}
					$result += [pscustomobject]@{
						DisplayName                   = $device.DisplayName
						AccountEnabled                = $device.AccountEnabled
						Manufacturer                  = $device.Manufacturer
						Model                         = $device.Model
						ManagementType                = $device.ManagementType
						DeviceOwnership               = $device.DeviceOwnership
						DeviceCategory                = $device.DeviceCategory
						EnrollmentType                = $device.EnrollmentType
						TrustType                     = $device.TrustType
						ProfileType                   = $device.ProfileType
						RegistrationDateTime          = $device.RegistrationDateTime
						ApproximateLastSignInDateTime = $device.ApproximateLastSignInDateTime
						DaysSinceLastSignIn           = $xdaysOld
						IsManaged                     = $device.IsManaged
						IsCompliant                   = $device.IsCompliant
						OnPremisesSyncEnabled         = $device.OnPremisesSyncEnabled
						OnPremisesLastSyncDateTime    = $device.OnPremisesLastSyncDateTime
						OperatingSystem               = $device.OperatingSystem
						OperatingSystemVersion        = $device.OperatingSystemVersion
						PhysicalIDs                   = $device.PhysicalIDs
						ID                            = $device.Id
						DeviceID                      = $device.DeviceId
						DeviceOwner                   = $(if ($owner) { $owner.DisplayName } else { $null })
						DeviceOwnerUPN                = $(if ($owner) { $owner.UserPrincipalName } else { $null })
					}
					$index++
				} # foreach
				if ($ShowProgress) {
					Write-Progress -Activity "Done" -Id 1 -Completed
				}
				$global:entraDevices = $result
			} else {
				Write-Host "No Entra devices found."
			}
		}
		$entraDevices
	} catch {
		Write-Error $_.Exception.Message
	}
}
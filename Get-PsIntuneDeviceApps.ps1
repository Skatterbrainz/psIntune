function Get-psIntuneDeviceApps {
	<#
	.SYNOPSIS
		Queries Installed Apps on Intune devices
	.DESCRIPTION
		Queries Installed Apps on Intune managed devices
	.PARAMETER Devices
		Data returned from Get-psIntuneDevice
	.PARAMETER UserName
		UserPrincipalName for authentication request
	.PARAMETER ShowProgress
		Display progress as data is exported (default is silent / no progress shown)
	.PARAMETER Expand
		Returns app information only. Default returns an object with Apps as a nested property
	.PARAMETER graphApiVersion
		Graph API version. Default is "beta"
	.EXAMPLE
		$devices = Get-psIntuneDevice -UserName $userid -Detail Detailed -ShowProgress
		$apps = Get-psIntuneDeviceApps -Devices $devices -UserName $userid -ShowProgress

		Gathers all Intune managed devices without their installed apps, then passes
		the $devices array to query the installed applications per device.
	.NOTES
		NAME: Get-psIntuneDeviceApps
	.LINK
		https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-psIntuneDeviceApps.md
	#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory)][ValidateNotNullOrEmpty()] $Devices,
		[parameter()][string] $UserName = $($global:psintuneuser),
		[parameter()][boolean] $ShowProgress = $False,
		[parameter()][boolean] $Expand = $False,
		[parameter()][string] $graphApiVersion = "beta"
	)
	if ([string]::IsNullOrEmpty($UserName)) { throw "Username was not provided" }
	[string]$global:psintuneuser = $UserName
	Get-psIntuneAuth -UserName $UserName
	$dcount = $Devices.Count
	$dx = 1
	$Devices | ForEach-Object {
		$DeviceID = $_.DeviceID
		$Name     = $_.DeviceName
		$OwnerUPN = $_.UserUPN     # "jsmith@contoso.com"
		$Domain   = $_.Domain      # "contoso.com"
		Write-Verbose "device name=$Name id=$DeviceID"
		if ($ShowProgress -eq $True) { 
			Write-Progress -Activity "Querying $dcount Intune managed devices" -Status "Reading device $dx of $dcount : $Name" -PercentComplete $(($dx/$dcount)*100) -id 1
		}
		try {
			$uriApps = "https://graph.microsoft.com/$graphApiVersion/deviceManagement/manageddevices('$DeviceID')?`$expand=detectedApps"
			$DetectedApps = @(Invoke-RestMethod -Uri $uriApps -Headers $authToken -Method Get -ErrorAction SilentlyContinue | Select-Object detectedApps)
			$apps = @($DetectedApps.detectedApps)
			Write-Verbose "returned: $($apps.Count) apps"
		}
		catch {
			Write-Warning "Failed to read device ($dx of $dcount) ID`=$DeviceID NAME`=$Name ERROR`=$($_.Exception.Message -join ';')"
		}
		finally {
			if ($Expand -eq $True) {
				$apps
			} else {
				[pscustomobject]@{
					DeviceName  = $Name
					DeviceID    = $DeviceID
					DeviceOwner = $OwnerUPN
					Domain      = $Domain
					Apps        = $apps
				}
			}
		}
		$dx++
	}
}

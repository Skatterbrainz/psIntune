function Get-psIntuneAzureADDevices {
	<#
	.SYNOPSIS
		Return AzureAD device accounts
	.DESCRIPTION
		Return all AzureAD tenant device accounts
	.PARAMETER UserName
		Account for logging into AzureAD
	.EXAMPLE
		Get-psIntuneAzureADDevices
	.NOTES
		Name: Get-psIntuneAzureADDevices
	.LINK
		https://github.com/Skatterbrainz/psintune/blob/master/docs/Get-psIntuneAzureADDevices.md
	#>
	[CmdletBinding()]
	param (
		[parameter()][string]$UserName = $($global:psintuneuser),
		[parameter()][switch]$ShowProgress
	)
	try {
		if ([string]::IsNullOrEmpty($UserName)) { throw "username was not provided" }
		#Get-psIntuneAuth -UserName $UserName
		if ($null -eq $global:aadauth) {
			$global:aadauth = Connect-AzureAd -AccountId $UserName -ErrorAction Stop
		}
		if (!$aadauth) { throw "AzureAD authentication was not completed" }

		Write-Host "Requesting devices from Azure AD tenant" -ForegroundColor Cyan
		$aadcomps = Get-AzureADDevice -All $True
		$acount = $aadcomps.Count
		$dx = 1
		Write-Host "Returned $($acount) devices from Azure AD" -ForegroundColor Cyan
		$aadcomps | Foreach-Object {
			$devname = $_.DisplayName
			$owner   = $null
			$upn     = $null
			if ($ShowProgress) { 
				Write-Progress -Activity "Querying $acount AzureAD devices" -Status "Reading device $dx of $acount : $devName" -PercentComplete $(($dx/$acount)*100) -id 1
			}	
			$devUserId = $($_.DevicePhysicalIds | Where-Object {$_ -match '\[USER\-GID\]'})
			if ($null -ne $devUserId) {
				$userGUID = $devUserId.Split(':')[1]
				$user = $null
				try {$user = Get-AzureADUser -ObjectId $userGUID -ErrorAction SilentlyContinue} catch {}
				if ($null -ne $user) {
					$owner = $user.DisplayName
					$upn   = $user.UserPrincipalName
				}
			}
			Write-Verbose "reading properties for: $devname"
			$llogin = $_.ApproximateLastLogonTimeStamp
			if (![string]::IsNullOrEmpty($llogin)) {
				$xdaysOld = (New-TimeSpan -Start $([datetime]$llogin) -End (Get-Date)).Days
			}
			else {
				$xdaysOld = $null
			}
			if (![string]::IsNullOrEmpty($_.LastDirSyncTime)) {
				$xSyncDays = (New-TimeSpan -Start $([datetime]$_.LastDirSyncTime) -End (Get-Date)).Days
			}
			else {
				$xSyncDays = $null
			}
			[pscustomobject]@{
				Name           = $devname
				DeviceId       = $_.DeviceId
				ObjectId       = $_.ObjectId
				Enabled        = $_.AccountEnabled
				OwnerName      = $owner
				OwnerUPN       = $upn
				OSName         = $_.DeviceOSType
				OSVersion      = $_.DeviceOSVersion
				TrustType      = $_.DeviceTrustType
				LastLogon      = $_.ApproximateLastLogonTimeStamp
				LastLogonDays  = $xdaysOld
				IsCompliant    = $($_.IsCompliant -eq $True)
				IsManaged      = $($_.IsManaged -eq $True)
				DirSyncEnabled = $($_.DirSyncEnabled -eq $True)
				LastDirSync    = $_.LastDirSyncTime
				LastSyncDays   = $xSyncDays
				ProfileType    = $_.ProfileType
			}
			$dx++
		}
	}
	catch {
		Write-Error $_.Exception.Message
	}
}

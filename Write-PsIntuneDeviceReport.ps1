function Write-psIntuneDeviceReport {
	<#
	.SYNOPSIS
		Export Inventory Data to Excel Workbook
	.DESCRIPTION
		Export Intune Device inventory data to Excel Workbook
	.PARAMETER IntuneDevices
		Device Data queried from Intune using Get-psIntuneDevice -Detail Full
		If not provided, data will be queried from Intune
	.PARAMETER IntuneApps
		Apps data returned from Get-psIntuneDeviceApps
		If not provided, data will be queried from Intune
	.PARAMETER AadDevices
		Device accounts from Azure AD.  If not provided, this data set is 
		simply excluded from the report.
	.PARAMETER OutputFolder
		Path for output file. Default is current user Documents path
	.PARAMETER Title
		Title to use for output filename, typically a customer or project name
	.PARAMETER DeviceOS
		Filter devices by operating system. Options: Android, iOS, Windows, All
		Default is All
	.PARAMETER StaleLimit
		Number of days since last Intune synchronization to consider as a stale account
		Default is 180
	.PARAMETER LowDiskGB
		Free disk space GB to indicate "low disk space".
		Default is 20
	.PARAMETER Overwrite
		If output file exists, with same name, it will be overwritten.
		Default is to abort if idential filename exists.
	.PARAMETER DateStamp
		Include datestamp in the output filename (default is "_YYYY-MM-DD" suffix)
	.PARAMETER Show
		Display workbook when export is complete. Default is to not show
	#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory)] [ValidateNotNullOrEmpty()] $IntuneDevices,
		[parameter(Mandatory)] [ValidateNotNullOrEmpty()] $IntuneApps,
		[parameter()] $AadDevices, 
		[parameter()][string] $OutputFolder = "$($env:USERPROFILE)\Documents",
		[parameter()][string] $Title = "",
		[parameter()][string][ValidateSet('All','Windows','Android','iOS')] $DeviceOS = 'All',
		[parameter()][ValidateRange(1,1000)][int] $StaleLimit = 180,
		[parameter()][ValidateRange(0,100)][int] $LowDiskGB = 20,
#		[parameter()][switch] $AzureAD,
		[parameter()][switch] $Overwrite,
		[parameter()][switch] $DateStamp,
		[parameter()][switch] $Show
	)
	$time1 = Get-Date
	Write-Host "Gathering data to generate report"
	if ($null -ne $AadDevices) {
		$AzureAD = $True
		$aadevs = $AadDevices
		#$aadevs = Get-psIntuneAzureADDevices -UserName $global:psintuneuser
	}
	if (!$DateStamp) {
		$xlFile = "$OutputFolder\IntuneDevices`_$Title.xlsx"
	}
	else {
		$xlFile = "$OutputFolder\IntuneDevices`_$Title`_$(Get-Date -f 'yyyy-MM-dd').xlsx"
	}
	
	Write-Verbose "output file = $xlFile"
	if ((Test-Path $xlFile) -and (!$Overwrite)) {
		Write-Warning "Output file exists [$xlFile]. Use -Overwrite to replace."
		break
	}
	if ($null -eq $IntuneDevices) {
		Write-Host "Requesting new query results..."
		$devs = Get-psIntuneDevice -Detail Detailed -ShowProgress
	}
	else {
		$devs = $IntuneDevices
	}

	if ($null -eq $IntuneApps) {
		Write-Host "Requesting application inventory for each device..."
		$apps = Get-psIntuneDeviceApps -Devices $devs -UserName $UserName -ShowProgress
	}
	else {
		$apps = $IntuneApps
	}

	Write-Host "Returned $($devs.Count) devices"
	if ($DeviceOS -ne 'All') {
		Write-Verbose "filtering devices on OSName = $DeviceOS"
		$devs = $devs | Where-Object {$_.OSName -match $DeviceOS}
		Write-Verbose "filtered to $($devs.Count) devices with $DeviceOS"
	}

	Write-Host "Applying filter rule: Base Devices"
	$intdevs   = $devs | Select-Object * -ExcludeProperty Apps
	Write-Host "Applying filter rule: Device Models"
	$models    = @($devs | Select-Object Manufacturer,Model | Group-Object -Property Manufacturer,Model | Select-Object Count,Name | Sort-Object Count -Descending)
	Write-Host "Applying filter rule: Orphaned Devices"
	$deldevs   = @($devs | Where-Object {$_.DeviceName -eq 'User deleted for this device'} | Select-Object * -ExcludeProperty Apps)
	Write-Host "Applying filter rule: Duplicate Devices"
	$dupedevs  = @($devs | Select-Object DeviceName,DeviceID | Group-Object -Property DeviceName | Where-Object {$_.Count -gt 1} | Select-Object Count,Name)
	Write-Host "Applying filter rule: Stale Devices"
	$staledevs = @($devs | Where-Object {$_.LastSyncDays -ge $StaleLimit} | Select-Object DeviceName,DeviceID,Category,Ownership,Manufacturer,Model,UserName,SerialNumber,LastSyncTime,LastSyncDays,EnrollDate)
	Write-Host "Applying filter rule: Devices with Low Disk Space"
	$lowdisk   = @($devs | Where-Object {$_.FreeSpaceGB -lt $LowDiskGB} | Select-Object * -ExcludeProperty Apps)
	Write-Host "Applying filter rule: Software"
	#$apps      = Get-psIntuneInstalledApps -DataSet $devs 

	#$allapps = @($apps.apps | Where-Object {(![string]::IsNullOrEmpty($_.displayName)) -and ($_.displayName -notmatch '\. \.')} | Sort-Object displayName)
	$allapps = $apps | Foreach-Object {
		$dn = $_.DeviceName
		$da = $_.apps
		$da | Foreach-Object {
			if (![string]::IsNullOrEmpty($_.displayName) -and ($_.displayName -notmatch '\. \.')) {
				[pscustomobject]@{
					DeviceName = $dn
					Product    = $_.displayName
					Version    = $_.version
				}
			}
		}
	}
	Write-Host "Applying filter rule: Software Install Counts"
	#$appcounts = $apps | Group-Object -Property ProductName | Select-Object Count,Name | Sort-Object Name -Unique
	$appcounts = $apps.apps | Where-Object {$_.DisplayName -notmatch '\. \.'} | Group-Object -Property DisplayName | Select-Object Count,Name | Sort-Object Count -Descending
	Write-Host "Applying filter rule: Distinct Software Products"
	#$distapps  = $apps | Select-Object ProductName,ProductType,DeviceName | Sort-Object ProductName -Unique
	$distapps = $apps.apps | Select-Object displayName,version | Sort-Object displayName -Unique
	if ($AzureAD) {
		if ($DeviceOS -ne 'All') {
			$aadevs = $aadevs | Where-Object { $_.OSName -match $DeviceOS } | Sort-Object Name 
			Write-Verbose "returned $($aadevs.Count) AzureAD devices running $DeviceOS"
		}
		$aadx = $aadevs | Select-Object Name,OSName,OSVersion | Sort-Object Name -Unique
		$aadupes = $aadevs | Group-Object Name | Where-Object {$_.Count -gt 1} | Select-Object Count,Name
	}

	Write-Host "Crunching statistics and stuff..."
	$stats = @()
	$stats += $intdevs | Group-Object -Property OSName,OSVersion | Sort-Object Count -Descending | Select-Object Name,Count | ForEach-Object {[pscustomobject]@{Name = 'OperatingSystem'; Property = $_.Name; Value = $_.Count}}
	$stats += $intdevs | Group-Object -Property Manufacturer,Model | Select-Object Name,Count | Sort-Object Count -Descending | ForEach-Object {[pscustomobject]@{Name = 'Models'; Property = $_.Name; Value = $_.Count}}
	$stats += $intdevs | Group-Object -Property Ownership | Select-Object Name,Count | Sort-Object Count -Descending | ForEach-Object {[pscustomobject]@{Name = 'Ownership'; Property = $_.Name; Value = $_.Count}}
	$stats += $intdevs | Group-Object -Property Category | Select-Object Name,Count | Sort-Object Count -Descending | ForEach-Object {[pscustomobject]@{Name = 'Category'; Property = $_.Name; Value = $_.Count}}
	$stats += $intdevs | Group-Object -Property UserName | Select-Object Name,Count | Where-Object {$_.Count -gt 1 -and $_.Name -ne ''} | Sort-Object Count -Descending | Select-Object -First 25 | ForEach-Object {[pscustomobject]@{Name = 'UserName'; Property = $_.Name; Value = $_.Count}}
	if ($AzureAD) {
		$stats += $aadevs | Group-Object -Property IsCompliant | Select-Object Name,Count | ForEach-Object {[pscustomobject]@{Name = 'Compliant'; Property = $_.Name; Value = $_.Count}}
		$stats += $aadevs | Group-Object -Property DirSyncEnabled | Select-Object Name,Count | ForEach-Object {[pscustomobject]@{Name = 'DirSyncEnabled'; Property = $_.Name; Value = $_.Count}}
		$stats += $aadevs | Group-Object -Property TrustType | Select-Object Name,Count | ForEach-Object {[pscustomobject]@{Name = 'TrustType'; Property = $_.Name; Value = $_.Count}}
		$stats += $aadevs | Group-Object -Property OSVersion | Select-Object Name,Count | ForEach-Object {$_.Name -ne '' -and $_.Count -gt 5} | Sort-Object Count -Descending | ForEach-Object {[pscustomobject]@{Name = 'OSVersion'; Property = $_.Name; Value = $_.Count}}
		$stats += $aadevs | Group-Object -Property LastLogonDays | ForEach-Object {$_.Name -gt 180 -and $_.Count -gt 10} | ForEach-Object {[pscustomobject]@{Name = 'DaysSinceLogon'; Count = $_.Count; Property = [int]$_.Name}} | Sort-Object Property -Descending
		$iMissing = $aadevs | Where-Object {$_.Name -notin $intdevs.DeviceName}
		$aMissing = $intdevs | Where-Object {$_.DeviceName -notin $aadevs.Name}
	}

	Write-Host "Exporting datasets: Summary"
	$stats | Export-Excel -Path $xlFile -WorksheetName "Summary" -ClearSheet -AutoSize -AutoFilter -FreezeTopRow
	Write-Host "Exporting datasets: Intune Devices ($($intdevs.Count))"
	$intdevs | Export-Excel -Path $xlFile -WorksheetName "IntuneDevices" -ClearSheet -AutoSize -AutoFilter -FreezeTopRowFirstColumn
	if ($AzureAD) {
		Write-Host "Exporting datasets: AzureAD devices ($($aadevs.Count))"
		$aadevs | Export-Excel -Path $xlFile -WorksheetName "AaDevices" -ClearSheet -AutoSize -AutoFilter -FreezeTopRowFirstColumn
		Write-Host "Exporting datasets: AzureAD unique devices ($($aadx.Count))"
		$aadx | Export-Excel -Path $xlFile -WorksheetName "AaDevicesUnique" -ClearSheet -AutoSize -AutoFilter -FreezeTopRow
		Write-Host "Exporting datasets: AzureAD duplicate devices ($($aadupes.Count))"
		$aadupes | Export-Excel -Path $xlFile -WorksheetName "AaDevicesDuplicates" -ClearSheet -AutoSize -AutoFilter -FreezeTopRowFirstColumn
	}
	Write-Host "Exporting datasets: Intune Device Models ($($models.Count))"
	$models | Export-Excel -Path $xlFile -WorksheetName "IntuneModels" -ClearSheet -AutoSize -AutoFilter -FreezeTopRow
	Write-Host "Exporting datasets: Intune Stale Devices ($($staledevs.Count))"
	$staledevs | Export-Excel -Path $xlFile -WorksheetName "IntuneStaleDevices" -ClearSheet -AutoSize -AutoFilter -FreezeTopRowFirstColumn
	Write-Host "Exporting datasets: Intune Duplicate Devices ($($dupedevs.Count))"
	$dupedevs | Export-Excel -Path $xlFile -WorksheetName "IntuneDuplicates" -ClearSheet -AutoSize -AutoFilter -FreezeTopRow
	Write-Host "Exporting datasets: Intune Orphaned Devices ($($deldevs.Count))"
	$deldevs | Export-Excel -Path $xlFile -WorksheetName "IntuneOrphaned" -ClearSheet -AutoSize -AutoFilter -FreezeTopRowFirstColumn
	Write-Host "Exporting datasets: Intune Devices with Low Disk Space ($($lowdisk.Count))"
	$lowdisk | Export-Excel -Path $xlFile -WorksheetName "IntuneLowDisk" -ClearSheet -AutoSize -AutoFilter -FreezeTopRowFirstColumn
	Write-Host "Exporting datasets: Intune Installed Software ($($apps.apps.Count))"
	$allapps | Sort-Object DeviceName,Product | Export-Excel -Path $xlFile -WorksheetName "IntuneSoftware" -ClearSheet -AutoSize -AutoFilter -FreezeTopRowFirstColumn
	Write-Host "Exporting datasets: Intune Software Install Counts ($($appcounts.Count))"
	$appcounts | Export-Excel -Path $xlFile -WorksheetName "IntuneInstallCounts" -ClearSheet -AutoSize -AutoFilter -FreezeTopRow
	Write-Host "Exporting datasets: Intune Software Distinct Products ($($distapps.Count))"
	$distapps | Export-Excel -Path $xlFile -WorksheetName "IntuneSoftwareUnique" -ClearSheet -AutoSize -AutoFilter -FreezeTopRow
	if ($AzureAD) {
		Write-Host "Exporting datasets: Devices missing from Intune ($($iMissing.Count))"
		$iMissing | Export-Excel -Path $xlFile -WorksheetName "IntuneMissing" -ClearSheet -AutoSize -AutoFilter -FreezeTopRowFirstColumn
		Write-Host "Exporting datasets: Devices missing from Azure AD ($($aMissing.Count))"
		$aMissing | Export-Excel -Path $xlFile -WorksheetName "AADMissing" -ClearSheet -AutoSize -AutoFilter -FreezeTopRowFirstColumn
	}
	if ($Show) { Start-Process -FilePath "$xlFile" }
	Write-Host "Export saved to $xlFile" -ForegroundColor Green

	$time2 = Get-Date
	$rt = New-TimeSpan -Start $time1 -End $time2
	Write-Host "Total runtime: $($rt.Hours)`:$($rt.Minutes)`:$($rt.Seconds) (hh`:mm`:ss)" -ForegroundColor Cyan
}
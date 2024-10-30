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
	.PARAMETER EntraDevices
		Device accounts from Azure AD.  If not provided, this data set is 
		simply excluded from the report.
	.PARAMETER OutputFolder
		Path for output file. Default is current user Documents path
	.PARAMETER ReportName
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
	.EXAMPLE
		$devices = Get-psIntuneDevice -DeviceName "Desktop123" -Detail Full
		$apps = Get-psIntuneInstalledApps -DataSet $devices
		Write-psIntuneDeviceReport -IntuneDevices $devices -IntuneApps $apps -OutputFolder "C:\Temp" -ReportName "MyReport"
	.EXAMPLE
		$devices = Get-psIntuneDevice -DeviceName "Desktop123" -Detail Full
		$apps = Get-psIntuneInstalledApps -DataSet $devices
		Write-psIntuneDeviceReport -IntuneDevices $devices -IntuneApps $apps -OutputFolder "C:\Temp" -ReportName "MyReport" -Show
	.EXAMPLE
		$devices = Get-psIntuneDevice -DeviceName "Desktop123" -Detail Full
		$apps = Get-psIntuneInstalledApps -DataSet $devices
		Write-psIntuneDeviceReport -IntuneDevices $devices -IntuneApps $apps -OutputFolder "C:\Temp" -ReportName "MyReport" -DeviceOS Windows
	.LINK
		https://github.com/Skatterbrainz/psIntune/blob/master/docs/Write-psIntuneDeviceReport.md
	#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory)] [ValidateNotNullOrEmpty()] $IntuneDevices,
		[parameter(Mandatory)] [ValidateNotNullOrEmpty()] $IntuneApps,
		[parameter()] $EntraDevices, 
		[parameter()][string] $OutputFolder = "$([System.Environment]::GetFolderPath('Personal'))",
		[parameter()][string] $ReportName = "",
		[parameter()][string][ValidateSet('All','Windows','Android','iOS')] $DeviceOS = 'All',
		[parameter()][ValidateRange(1,1000)][int] $StaleLimit = 180,
		[parameter()][ValidateRange(0,100)][int] $LowDiskGB = 20,
		[parameter()][boolean] $Overwrite = $False,
		[parameter()][boolean] $DateStamp = $False,
		[parameter()][boolean] $Show = $False,
		[parameter()][boolean] $FullExport = $False
	)
	$time1 = Get-Date
	Write-Host "Gathering data to generate report"
	if ($null -ne $EntraDevices) {
		$Entra = $True
		$aadevs = $EntraDevices
	}
	if ($DateStamp -ne $True) {
		$xlFile = Join-Path $OutputFolder "IntuneDevices_$($ReportName).xlsx"
	} else {
		$xlFile = Join-Path $OutputFolder "IntuneDevices_$($ReportName)_$(Get-Date -f 'yyyy-MM-dd').xlsx"
	}
	
	Write-Verbose "output file = $xlFile"
	if ((Test-Path $xlFile) -and ($Overwrite -ne $True)) {
		Write-Warning "Output file exists [$xlFile]. Use -Overwrite to replace."
		break
	}

	if ($FullExport -eq $True) {
		Write-Host "Exporting full dataset to $xlFile"
		
		exportTable -Path $xlFile -TabName "IntuneDevices" -Table $IntuneDevices
		exportTable -Path $xlFile -TabName "IntuneSoftware" -Table $IntuneApps
		exportTable -Path $xlFile -TabName "EntraDevices" -Table $EntraDevices
		if ($Show -eq $True) { Start-Process -FilePath "$xlFile" }
		Write-Host "Export saved to $xlFile" -ForegroundColor Green
	} else {
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
		$allapps = $IntuneApps | Foreach-Object {
			$dn    = $_.DeviceName
			$owner = $_.DeviceOwner
			$dom   = $_.Domain
			$da    = $_.apps
			$da | Foreach-Object {
				if (![string]::IsNullOrEmpty($_.displayName) -and ($_.displayName -notmatch '\. \.')) {
					[pscustomobject]@{
						DeviceName  = $dn
						DeviceOwner = $owner
						Domain      = $dom
						Product     = $_.displayName
						Version     = $_.version
					}
				}
			}
		}
		Write-Host "Applying filter rule: Software Install Counts"
		$appcounts = $IntuneApps.apps | Where-Object {$_.DisplayName -notmatch '\. \.'} |
			Group-Object -Property DisplayName | Select-Object Count,Name | Sort-Object Count -Descending

		Write-Host "Applying filter rule: Distinct Software Products"
		$distapps = $IntuneApps.apps | Select-Object displayName,version | Sort-Object displayName -Unique
		if ($Entra) {
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
		if ($Entra) {
			$stats += $aadevs | Group-Object -Property IsCompliant | Select-Object Name,Count | ForEach-Object {[pscustomobject]@{Name = 'Compliant'; Property = $_.Name; Value = $_.Count}}
			$stats += $aadevs | Group-Object -Property DirSyncEnabled | Select-Object Name,Count | ForEach-Object {[pscustomobject]@{Name = 'DirSyncEnabled'; Property = $_.Name; Value = $_.Count}}
			$stats += $aadevs | Group-Object -Property TrustType | Select-Object Name,Count | ForEach-Object {[pscustomobject]@{Name = 'TrustType'; Property = $_.Name; Value = $_.Count}}
			$stats += $aadevs | Group-Object -Property OSVersion | Select-Object Name,Count | ForEach-Object {$_.Name -ne '' -and $_.Count -gt 5} | Sort-Object Count -Descending | ForEach-Object {[pscustomobject]@{Name = 'OSVersion'; Property = $_.Name; Value = $_.Count}}
			$stats += $aadevs | Group-Object -Property LastLogonDays | ForEach-Object {$_.Name -gt 180 -and $_.Count -gt 10} | ForEach-Object {[pscustomobject]@{Name = 'DaysSinceLogon'; Count = $_.Count; Property = [int]$_.Name}} | Sort-Object Property -Descending
			$iMissing = $aadevs | Where-Object {$_.Name -notin $intdevs.DeviceName}
			$aMissing = $intdevs | Where-Object {$_.DeviceName -notin $aadevs.Name}
		}

		Write-Host "Exporting datasets: Summary"
		exportTable -Path $xlFile -TabName "Summary" -Table $stats
		#$stats | Export-Excel -Path $xlFile -WorksheetName "Summary" -ClearSheet -AutoSize -AutoFilter -FreezeTopRow

		Write-Host "Exporting datasets: Intune Devices ($($intdevs.Count))"
		exportTable -Path $xlFile -TabName "IntuneDevices" -Table $intdevs
		#$intdevs | Export-Excel -Path $xlFile -WorksheetName "IntuneDevices" -ClearSheet -AutoSize -AutoFilter -FreezeTopRowFirstColumn

		if ($Entra) {

			Write-Host "Exporting datasets: AzureAD devices ($($aadevs.Count))"
			exportTable -Path $xlFile -TabName "EntraDevices" -Table $aadevs
			#$aadevs | Export-Excel -Path $xlFile -WorksheetName "AaDevices" -ClearSheet -AutoSize -AutoFilter -FreezeTopRowFirstColumn
			
			Write-Host "Exporting datasets: AzureAD unique devices ($($aadx.Count))"
			exportTable -Path $xlFile -TabName "AaDevicesUnique" -Table $aadx
			#$aadx | Export-Excel -Path $xlFile -WorksheetName "AaDevicesUnique" -ClearSheet -AutoSize -AutoFilter -FreezeTopRow
			
			Write-Host "Exporting datasets: AzureAD duplicate devices ($($aadupes.Count))"
			exportTable -Path $xlFile -TabName "AaDevicesDuplicates" -Table $aadupes
			#$aadupes | Export-Excel -Path $xlFile -WorksheetName "AaDevicesDuplicates" -ClearSheet -AutoSize -AutoFilter -FreezeTopRowFirstColumn
		}
		Write-Host "Exporting datasets: Intune Device Models ($($models.Count))"
		exportTable -Path $xlFile -TabName "IntuneModels" -Table $models
		#$models | Export-Excel -Path $xlFile -WorksheetName "IntuneModels" -ClearSheet -AutoSize -AutoFilter -FreezeTopRow

		Write-Host "Exporting datasets: Intune Stale Devices ($($staledevs.Count))"
		exportTable -Path $xlFile -TabName "IntuneStaleDevices" -Table $staledevs
		#$staledevs | Export-Excel -Path $xlFile -WorksheetName "IntuneStaleDevices" -ClearSheet -AutoSize -AutoFilter -FreezeTopRowFirstColumn

		Write-Host "Exporting datasets: Intune Duplicate Devices ($($dupedevs.Count))"
		exportTable -Path $xlFile -TabName "IntuneDuplicates" -Table $dupedevs
		#$dupedevs | Export-Excel -Path $xlFile -WorksheetName "IntuneDuplicates" -ClearSheet -AutoSize -AutoFilter -FreezeTopRow

		Write-Host "Exporting datasets: Intune Orphaned Devices ($($deldevs.Count))"
		exportTable -Path $xlFile -TabName "IntuneOrphaned" -Table $deldevs
		#$deldevs | Export-Excel -Path $xlFile -WorksheetName "IntuneOrphaned" -ClearSheet -AutoSize -AutoFilter -FreezeTopRowFirstColumn

		Write-Host "Exporting datasets: Intune Devices with Low Disk Space ($($lowdisk.Count))"
		exportTable -Path $xlFile -TabName "IntuneLowDisk" -Table $lowdisk
		#$lowdisk | Export-Excel -Path $xlFile -WorksheetName "IntuneLowDisk" -ClearSheet -AutoSize -AutoFilter -FreezeTopRowFirstColumn

		Write-Host "Exporting datasets: Intune Installed Software ($($apps.apps.Count))"
		exportTable -Path $xlFile -TabName "IntuneSoftware" -Table $($allapps | Sort-Object DeviceName,DeviceOwner,Product)
		#$allapps | Sort-Object DeviceName,DeviceOwner,Product | Export-Excel -Path $xlFile -WorksheetName "IntuneSoftware" -ClearSheet -AutoSize -AutoFilter -FreezeTopRowFirstColumn

		Write-Host "Exporting datasets: Intune Software Install Counts ($($appcounts.Count))"
		exportTable -Path $xlFile -TabName "IntuneInstallCounts" -Table $appcounts
		#$appcounts | Export-Excel -Path $xlFile -WorksheetName "IntuneInstallCounts" -ClearSheet -AutoSize -AutoFilter -FreezeTopRow

		Write-Host "Exporting datasets: Intune Software Distinct Products ($($distapps.Count))"
		exportTable -Path $xlFile -TabName "IntuneSoftwareUnique" -Table $distapps
		#$distapps | Export-Excel -Path $xlFile -WorksheetName "IntuneSoftwareUnique" -ClearSheet -AutoSize -AutoFilter -FreezeTopRow
		if ($Entra) {
			Write-Host "Exporting datasets: Devices missing from Intune ($($iMissing.Count))"
			$iMissing | Export-Excel -Path $xlFile -WorksheetName "IntuneMissing" -ClearSheet -AutoSize -AutoFilter -FreezeTopRowFirstColumn
			Write-Host "Exporting datasets: Devices missing from Azure AD ($($aMissing.Count))"
			$aMissing | Export-Excel -Path $xlFile -WorksheetName "AADMissing" -ClearSheet -AutoSize -AutoFilter -FreezeTopRowFirstColumn
		}
		if ($Show -eq $True) { Start-Process -FilePath "$xlFile" }

		Write-Host "Export saved to $xlFile" -ForegroundColor Green
	}
	$time2 = Get-Date
	$rt = New-TimeSpan -Start $time1 -End $time2
	Write-Host "Total runtime: $($rt.Hours)`:$($rt.Minutes)`:$($rt.Seconds) (hh`:mm`:ss)" -ForegroundColor Cyan
}
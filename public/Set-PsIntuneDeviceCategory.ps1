function Set-PSIntuneDeviceCategory {
	<#
	.SYNOPSIS
		Batch update Intune device category assignment
	.DESCRIPTION
		Batch update Intune device category assignment using
		an input file (csv or txt) to filter the computer names
	.PARAMETER InputFile
		Path and name of .CSV or .TXT input file
		CSV file must have a column named "Computer"
		TXT file must be computer names only, one per line
	.PARAMETER ComputerName
		Computer name(s) to process when InputFile is not used. Comma-delimited string)
	.PARAMETER CategoryName
		A valid category name.  If the name does not exist in the
		Intune subscription, it will return an error
	.PARAMETER UserName
		UPN for user with credentials
	.EXAMPLE
		Set-PSIntuneDeviceCategory -InputFile ".\computers.txt" -CategoryName "Personal" -UserName "jdoe@contoso.com"
	.EXAMPLE
		Set-PSIntuneDeviceCategory -ComputerName "Computer1,Computer2" -CategoryName "Corporate" -UserName "jdoe@contoso.com"
	.NOTES
		Requires an Azure AD app registration with Application permissions assigned:
		Device.Read / Read.All / ReadWrite.All
		DeviceManagementManagedDevice.Read.All / ReadWrite.All
	.LINK
		https://github.com/Skatterbrainz/psIntune/blob/master/docs/Set-PSIntuneDeviceCategory.md
	#>
	[CmdletBinding(SupportsShouldProcess=$True,DefaultParameterSetName='ComputerName')]
	param (
		[parameter(ParameterSetName = 'File', Mandatory=$False)][string] $InputFile = "",
		[parameter(ParameterSetName = 'ComputerName', Mandatory=$False)][string] $ComputerName = "",
		[parameter(Mandatory)][string] $CategoryName,
		[parameter(Mandatory)][string] $UserName
	)
	try {
		if ([string]::IsNullOrEmpty($InputFile) -and [string]::IsNullOrEmpty($ComputerName)) {
			throw "Neither InputFile or ComputerName were provided."
		}
		if (Get-Module AzureAD) {
			Remove-Module AzureAD -Force
		}
		Import-Module AzureADPreview
		Get-psIntuneAuth -UserName $UserName
		if (![string]::IsNullOrEmpty($InputFile)) {
			if (-not(Test-Path $InputFile)) {
				throw "file not found: $InputFile"
			}
			if ($InputFile.EndsWith(".csv")) {
				[array]$computers = Import-Csv -Path $InputFile | Select-Object Computer
			} elseif ($InputFile.EndsWith(".txt")) {
				[array]$computers = Get-Content -Path $InputFile | Where-Object {-not($($_).ToString().StartsWith(';'))}
			} else {
				throw "invalid file type (.csv or .txt only)"
			}
		} else {
			$computers = @($ComputerName -split ',')
		}

		if ($computers.Count -gt 0) {
			Write-Host "processing $($computers.Count) computer names"
		} else {
			throw "no computers were imported from file"
		}

#		Write-Verbose "connecting to: azure ad"
#		$azconn = Connect-AzureAD -Credential $Credential -ErrorAction Stop
#		if (!$WhatIfPreference) { Write-Verbose "connected to $($azconn.TenantDomain)" }

		Write-Verbose "connecting to: msgraph"
		Connect-MSGraph

		$null = Update-MSGraphEnvironment -SchemaVersion 'beta'
		[string]$baseUrl = "https://graph.microsoft.com/beta"

		Write-Verbose "getting devices"
		[array]$devices = Get-PsIntuneDevice -UserName $UserName -Detail Summary
		#[array]$devices = Get-DeviceManagement_ManagedDevices
		Write-Verbose "returned $($devices.Count) devices"

		Write-Verbose "getting device categories"
		[array]$cats = Get-DeviceManagement_DeviceCategories
		Write-Verbose "returned $($cats.Count) categories"

		Write-Verbose "validating requested category: $CategoryName"
		$cat = $cats | Where-Object {$_.displayName -eq $CategoryName}
		if ($null -eq $cat) { throw "category not found: $CategoryName" }
		$DeviceCategory = $cat.id
		Write-Verbose "categoryId........ $DeviceCategory"

		foreach ($computer in $computers) {
			$device = $devices | Where-Object {$_.DeviceName -eq $computer}
			if ($null -eq $device) {
				Write-Warning "device not found: $computer"
			} else {
				$deviceid = $device.DeviceID
				Write-Verbose "deviceName........ $computer"
				Write-Verbose "deviceId.......... $deviceId"
				Write-Verbose "current-category.. $($device.deviceCategoryDisplayName)"
				Set-DeviceCategory -DeviceID $deviceid -category $DeviceCategory -BaseUrl $baseUrl
			}
		}
	} catch {
		Write-Error $_.Exception.Message
	}
}
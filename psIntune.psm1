<#
.COPYRIGHT
Portions of this are derived from Microsoft content on GitHub at the following URL:

https://github.com/microsoftgraph/powershell-intune-samples/blob/master/ManagedDevices/ManagedDevices_Apps_Get.ps1

Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.
#>

#region Microsoft GitHub sample code

#$graphApiVersion = "beta"

function get-AuthToken {
	<#
	.SYNOPSIS
		This function is used to authenticate with the Graph API REST interface
	.DESCRIPTION
		The function authenticate with the Graph API Interface with the tenant name
	.PARAMETER User
		UserName for cloud services access
	.EXAMPLE
		Get-AuthToken -User "john.doe@contoso.com"

		Authenticates user with the Graph API interface
	.NOTES
		NAME: Get-AuthToken
	#>
	[cmdletbinding()]
	param (
		[parameter(Mandatory)] $User
	)

	$userUpn = New-Object "System.Net.Mail.MailAddress" -ArgumentList $User
	$tenant = $userUpn.Host

	Write-Host "Checking for AzureAD module..."
	$AadModule = Get-Module -Name "AzureAD" -ListAvailable

	if ($null -eq $AadModule) {
		Write-Host "AzureAD PowerShell module not found, looking for AzureADPreview"
		$AadModule = Get-Module -Name "AzureADPreview" -ListAvailable
	}

	if ($null -eq $AadModule) {
		Write-Host
		Write-Host "AzureAD Powershell module not installed..." -f Red
		Write-Host "Install by running 'Install-Module AzureAD' or 'Install-Module AzureADPreview' from an elevated PowerShell prompt" -f Yellow
		Write-Host "Script can't continue..." -f Red
		Write-Host
		exit
	}
	# Getting path to ActiveDirectory Assemblies
	# If the module count is greater than 1 find the latest version
	if ($AadModule.count -gt 1){
		$Latest_Version = ($AadModule | Select-Object version | Sort-Object)[-1]
		$aadModule = $AadModule | Where-Object { $_.version -eq $Latest_Version.version }
		# Checking if there are multiple versions of the same module found
		if($AadModule.count -gt 1){
			$aadModule = $AadModule | Select-Object -Unique
		}
		$adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
		$adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
	}
	else {
		$adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
		$adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
	}

	[System.Reflection.Assembly]::LoadFrom($adal) | Out-Null
	[System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null

	$clientId = "d1ddf0e4-d672-4dae-b554-9d5bdfd93547"
	$redirectUri = "urn:ietf:wg:oauth:2.0:oob"
	$resourceAppIdURI = "https://graph.microsoft.com"
	$authority = "https://login.microsoftonline.com/$Tenant"

	try {
		$authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority
		# https://msdn.microsoft.com/en-us/library/azure/microsoft.identitymodel.clients.activedirectory.promptbehavior.aspx
		# Change the prompt behaviour to force credentials each time: Auto, Always, Never, RefreshSession
		$platformParameters = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters" -ArgumentList "Auto"
		$userId = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier" -ArgumentList ($User, "OptionalDisplayableId")
		$authResult = $authContext.AcquireTokenAsync($resourceAppIdURI,$clientId,$redirectUri,$platformParameters,$userId).Result

		# If the accesstoken is valid then create the authentication header
		if ($authResult.AccessToken){
			# Creating header for Authorization token
			$authHeader = @{
				'Content-Type'='application/json'
				'Authorization'="Bearer " + $authResult.AccessToken
				'ExpiresOn'=$authResult.ExpiresOn
			}
			return $authHeader
		}
		else {
			Write-Host "Authorization Access Token is null, please re-run authentication..." -ForegroundColor Red
			break
		}
	}
	catch {
		Write-Error $_.Exception.Message
		Write-Error $_.Exception.ItemName
		break
	}
}

function get-psIntuneAuth {
	<#
	.SYNOPSIS
		Returns authentication token object
	.PARAMETER UserName
		UserName for cloud services access
	.EXAMPLE
		Get-psIntuneAuth -UserName "john.doe@contoso.com"
	.NOTES
		Name: Get-psIntuneAuth
	#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory)][string] $UserName
	)
	# Checking if authToken exists before running authentication
	if ($global:authToken) {

		# Setting DateTime to Universal time to work in all timezones
		$DateTime = (Get-Date).ToUniversalTime()

		# If the authToken exists checking when it expires
		$TokenExpires = ($authToken.ExpiresOn.datetime - $DateTime).Minutes

		if ($TokenExpires -le 0){
			Write-Host "Authentication Token expired" $TokenExpires "minutes ago" -ForegroundColor Yellow
			# Defining Azure AD tenant name, this is the name of your Azure Active Directory (do not use the verified domain name)
			$global:authToken = Get-AuthToken -User $UserName
		}
	}
	else {
		# Authentication doesn't exist, calling Get-AuthToken function
		$global:authToken = Get-AuthToken -User $UserName
	}
}

function get-MsGraphData($Path) {
	<#
	.SYNOPSIS
		Returns MS Graph data from (beta) REST API query
	.PARAMETER Path
		REST API URI path suffix
	.NOTES
		This function was derived from https://www.dowst.dev/search-intune-for-devices-with-application-installed/
		(Thanks to Matt Dowst)
	#>
	$FullUri = "https://graph.microsoft.com/$graphApiVersion/$Path"
	[System.Collections.Generic.List[PSObject]]$Collection = @()
	$NextLink = $FullUri
	do {
		$Result = Invoke-RestMethod -Method Get -Uri $NextLink -Headers $AuthHeader
		if ($Result.'@odata.count') {
			$Result.value | ForEach-Object{$Collection.Add($_)}
		} 
		else {
			$Collection.Add($Result)
		}
		$NextLink = $Result.'@odata.nextLink'
	} while ($NextLink)
	return $Collection
}

function Get-ManagedDevices(){
	<#
	.SYNOPSIS
		This function is used to get Intune Managed Devices from the Graph API REST interface

	.DESCRIPTION
		The function connects to the Graph API Interface and gets any Intune Managed Device

	.PARAMETER IncludeEAS
		Switch to include EAS devices (not included by default)

	.PARAMETER ExcludeMDM
		Switch to exclude MDM devices (not excluded by default)

	.EXAMPLE
		Get-ManagedDevices

		Returns all managed devices but excludes EAS devices registered within the Intune Service

	.EXAMPLE
		Get-ManagedDevices -IncludeEAS

		Returns all managed devices including EAS devices registered within the Intune Service

	.NOTES
		NAME: Get-ManagedDevices

	.LINK
		https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-ManagedDevices.md
	#>
	[cmdletbinding()]
	param (
		[parameter(Mandatory)][string] $UserName,
		[parameter()][string] $DeviceName = "",
		[parameter()][switch] $IncludeEAS,
		[parameter()][switch] $ExcludeMDM
	)
	#$graphApiVersion = "beta"
	$Resource = "deviceManagement/managedDevices"
	try {
		Get-psIntuneAuth -UserName $UserName
		$Count_Params = 0
		if ($IncludeEAS.IsPresent){ $Count_Params++ }
		if ($ExcludeMDM.IsPresent){ $Count_Params++ }
		if ($Count_Params -gt 1) {
			Write-Warning "Multiple parameters set, specify a single parameter -IncludeEAS, -ExcludeMDM or no parameter against the function"
			#Write-Host
			break
		}
		elseif ($IncludeEAS) {
			Write-Verbose "IncludeEAS = true"
			$uri = "https://graph.microsoft.com/$graphApiVersion/$Resource"
		}
		elseif ($ExcludeMDM) {
			Write-Verbose "ExcludeMDM = true"
			$uri = "https://graph.microsoft.com/$graphApiVersion/$Resource`?`$filter=managementAgent eq 'eas'"
		}
		else {
			if (![string]::IsNullOrEmpty($DeviceName)) {
				Write-Verbose "DeviceName = $DeviceName"
				$uri = "https://graph.microsoft.com/$graphApiVersion/$Resource`?`$filter=deviceName eq '$DeviceName' and managementAgent eq 'mdm' and managementAgent eq 'easmdm'"
			}
			else {
				Write-Verbose "Default = True"
				$uri = "https://graph.microsoft.com/$graphApiVersion/$Resource`?`$filter=managementAgent eq 'mdm' and managementAgent eq 'easmdm'"
			}
			Write-Warning "EAS Devices are excluded by default, please use -IncludeEAS if you want to include those devices"
			#Write-Host
		}
		$response = (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get)
		$Devices = $response.Value
		$DevicesNextLink = $response."@odata.nextLink"
		while ($DevicesNextLink) {
			$response = (Invoke-RestMethod -Uri $DevicesNextLink -Headers $authToken -Method Get)
			$DevicesNextLink = $response."@odata.nextLink"
			$Devices += $response.value 
		}
		$Devices
	}
	catch {
		$ex = $_.Exception
		$errorResponse = $ex.Response.GetResponseStream()
		$reader = New-Object System.IO.StreamReader($errorResponse)
		$reader.BaseStream.Position = 0
		$reader.DiscardBufferedData()
		$responseBody = $reader.ReadToEnd();
		Write-Warning "Response content:`n$responseBody"
		Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
		Write-Host
		break
	}
}
#endregion 

function Get-psIntuneAzureADUser() {
	<#
	.SYNOPSIS
		This function is used to get AAD Users from the Graph API REST interface
	.DESCRIPTION
		The function connects to the Graph API Interface and gets any users registered with AAD
	.EXAMPLE
		Get-psIntuneAzureADUser
		Returns all users registered with Azure AD
	.EXAMPLE
		Get-psIntuneAzureADUser -userPrincipleName user@domain.com
		Returns specific user by UserPrincipalName registered with Azure AD
	.NOTES
		NAME: Get-psIntuneAzureADUser
	.LINK
		https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-psIntuneAzureADUser.md
	#>
	[cmdletbinding()]
	param (
		[parameter()][string] $userPrincipalName,
		[parameter()][string] $Property
	)
	$User_resource = "users"

	try {
		if ([string]::IsNullOrEmpty($userPrincipalName)) {
			$uri = "https://graph.microsoft.com/$graphApiVersion/$($User_resource)"
			(Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
		}
		else {
			if ([string]::IsNullOrEmpty($Property)) {
				$uri = "https://graph.microsoft.com/$graphApiVersion/$($User_resource)/$userPrincipalName"
				Write-Verbose $uri
				Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get
			}
			else {
				$uri = "https://graph.microsoft.com/$graphApiVersion/$($User_resource)/$userPrincipalName/$Property"
				Write-Verbose $uri
				(Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
			}
		}
	}
	catch {
		$ex = $_.Exception
		$errorResponse = $ex.Response.GetResponseStream()
		$reader = New-Object System.IO.StreamReader($errorResponse)
		$reader.BaseStream.Position = 0
		$reader.DiscardBufferedData()
		$responseBody = $reader.ReadToEnd();
		Write-Host "Response content:`n$responseBody" -f Red
		Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
		#Write-Host
		break
	}
}

function Get-psIntuneAzureADDevices {
	<#
	.SYNOPSIS
		Return AzureAD device accounts
	.DESCRIPTION
		Return all AzureAD tenant device accounts
	.EXAMPLE
		Get-psIntuneAzureADDevices
	.NOTES
		Name: Get-psIntuneAzureADDevices
	.LINK
		https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-psIntuneAzureADDevices.md
	#>
	[CmdletBinding()]
	param()
	try {
		if (!$AADCred) { 
			Write-Host "Connecting to AzureAD, you may be required to confirm MFA" -ForegroundColor Yellow
			$Global:AADCred = Connect-AzureAD 
		}
		if (!$AADCred) {
			throw "AzureAD authentication was not completed"
		}
		Write-Host "Requesting devices from Azure AD tenant" -ForegroundColor Cyan
		$aadcomps = Get-AzureADDevice -All $True
		Write-Host "Returned $($aadcomps.Count) devices from Azure AD" -ForegroundColor Cyan
		$aadcomps | Foreach-Object {
			$devname = $_.DisplayName
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
		}
	}
	catch {
		Write-Error $_.Exception.Message
	}
}

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
	.PARAMETER ShowProgress
		Display progress as data is exported (default is silent / no progress shown)
	.PARAMETER Detail
		Controls the level of granularity of the results:
		* Summary - returns basic device information only
		* Detailed - returns detailed device information
		* Full - returns detailed device information with installed applications
		* Raw - returns raw Graph API results only
	.EXAMPLE
		$devices = Get-psIntuneDevice -UserName "john.doe@contoso.com" -DeviceName "Desktop123" -Detail Detailed

		Returns detailed data for one device without installed applications
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
		[parameter(Mandatory)][string] $UserName,
		[parameter()][string] $DeviceName = "",
		[parameter()][ValidateSet('Full','Detailed','Summary','Raw')][string] $Detail = 'Summary',
		[parameter()][switch] $ShowProgress,
		[parameter()][string] $graphApiVersion = "beta"
	)
	try {
		if (![string]::IsNullOrEmpty($DeviceName)) {
			$devices = Get-ManagedDevices -Username $UserName -DeviceName $DeviceName
		}
		else {
			$devices = Get-ManagedDevices -UserName $UserName
		}
		$dcount = $Devices.Count
		$dx = 1
		Write-Verbose "returned $dcount devices"
		if ($Detail -eq 'Full') {
			Write-Warning "Full option takes the longest to process. This may take a few minutes."
		}
		foreach ($Device in $Devices){
			if ($ShowProgress) { 
				Write-Progress -Activity "Found $dcount devices" -Status "Reading device $dx of $dcount" -PercentComplete $(($dx/$dcount)*100) -id 1
			}
			$DeviceID = $Device.id
			$LastSync = $Device.lastSyncDateTime
			$SyncDays = (New-TimeSpan -Start $LastSync -End (Get-Date)).Days
			switch ($Detail) {
				'Summary' {
					[pscustomobject]@{
						DeviceName   = $Device.DeviceName
						DeviceID     = $DeviceID
						UserName     = $Device.userDisplayName
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
					[pscustomobject]@{
						DeviceName   = $Device.DeviceName
						DeviceID     = $DeviceID
						Manufacturer = $Device.manufacturer
						Model        = $Device.model 
						UserName     = $Device.userDisplayName
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
						LastSyncTime = $LastSync
						LastSyncDays = $SyncDays
						Compliant    = $compliant
						AutoPilot    = $Device.autopilotEnrolled
					}	
				}
				'Full' {
					$uriApps = "https://graph.microsoft.com/$graphApiVersion/deviceManagement/manageddevices('$DeviceID')?`$expand=detectedApps"
					$DetectedApps = (Invoke-RestMethod -Uri $uriApps -Headers $authToken -Method Get).detectedApps
					$compliant = $($Device.complianceState -eq $True)
					$disksize  = [math]::Round(($Device.totalStorageSpaceInBytes / 1GB),2)
					$freespace = [math]::Round(($Device.freeStorageSpaceInBytes / 1GB),2)
					$mem       = [math]::Round(($Device.physicalMemoryInBytes / 1GB),2)
					[pscustomobject]@{
						DeviceName   = $Device.DeviceName
						DeviceID     = $DeviceID
						Manufacturer = $Device.manufacturer
						Model        = $Device.model 
						UserName     = $Device.userDisplayName
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
						LastSyncTime = $LastSync
						LastSyncDays = $SyncDays
						Compliant    = $compliant
						AutoPilot    = $Device.autopilotEnrolled
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
		Write-Error $_.Exception.Message 
	}
}

function Get-psIntuneInstalledApps {
	<#
	.SYNOPSIS
		Returns App inventory data from Intune Device data set

	.DESCRIPTION
		Returns App inventory data from Intune Device data set

	.PARAMETER DataSet
		Data returned from Get-psIntuneDevice

	.EXAMPLE
		$devices = Get-psIntuneDevice -UserName "john.doe@contoso.com"
		$applist = Get-psIntuneInstalledApps -DataSet $devices

	.NOTES
		NAME: Get-psIntuneInstalledApps

	.LINK
		https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-psIntuneInstalledApps.md

	#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$True)]
		[ValidateNotNull()] $DataSet,
		[parameter()][switch] $GroupByName
	)
	$badnames = ('. .','. . .','..','...')
	Write-Verbose "reading $($DataSet.Count) objects"
	$appcount = 0
	$result = $DataSet | Foreach-Object {
		$devicename = $_.DeviceName
		$apps = $_.Apps 
		if ($null -ne $Apps) {
			foreach ($app in $apps) {
				$displayName = $($app.displayName).ToString().Trim()
				if (![string]::IsNullOrEmpty($displayName)) {
					if ($displayName -notin $badnames) {
						if ($($app.Id).Length -gt 36) {
							$ptype = 'WindowsStore'
						}
						elseif ($($app.Id).Length -eq 36) {
							$ptype = 'Win32'
						}
						else {
							$ptype = 'Other'
						}
						[pscustomobject]@{
							ProductName    = $displayName
							ProductVersion = $($app.version).ToString().Trim()
							ProductCode    = $app.Id
							ProductType    = $ptype
							DeviceName     = $devicename
						}
					}
				}
			}
			$appcount++
		}
		else {
			Write-Verbose "$devicename - has no apps"
		}
	}
	if ($appcount -eq 0) {
		Write-Warning "DataSet objects have no applications linked. Use [-Detail Full] option with Get-psIntuneDevice"
	}
	if ($GroupByName) {
		$result | Group-Object -Property ProductName | Select-Object Count,Name | Sort-Object Name -Unique
	}
	else {
		$result
	}
}

function Get-psIntuneDevicesWithApp {
	<#
	.SYNOPSIS
		Returns Intune managed devices having a specified App installed

	.DESCRIPTION
		Returns Intune managed devices having a specified App installed

	.PARAMETER AppDataSet
		Applications dataset returned from Get-DsIntuneDeviceApps().
		If not provided, Devices are queried automatically, which will incur additional time.

	.PARAMETER Application
		Name, or wildcard name, of App to search for

	.PARAMETER UserName
		UserPrincipalName for authentication request

	.PARAMETER ShowProgress
		Display progress during execution (default is silent / no progress shown)

	.EXAMPLE
		Get-psIntuneDevicesWithApp -Application "*Putty*" -UserName "john.doe@contoso.com"

		Returns list of Intune-managed devices which have any app name containing "Putty" installed

	.EXAMPLE
		Get-psIntuneDevicesWithApp -Application "*Putty*" -UserName "john.doe@contoso.com" -ShowProgress

		Returns list of Intune-managed devices which have any apps name containing "Putty" installed, and displays progress during execution

	.NOTES
		NAME: Get-psIntuneDevicesWithApp
		This function was derived almost entirely from https://www.dowst.dev/search-intune-for-devices-with-application-installed/
		(Thanks to Matt Dowst)

	.LINK
		https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-psIntuneDevicesWithApp.md

	#>
	[CmdletBinding()]
	param (
		[parameter()] $AppDataSet,
		[parameter(Mandatory)][ValidateNotNullOrEmpty()][string] $Application,
		[parameter()][string] $Version,
		[parameter(Mandatory)][ValidateNotNullOrEmpty()][string] $Username,
		[parameter()][switch] $ShowProgress
	)
	Write-Verbose "Getting authentication token"
	$AuthHeader = Get-AuthToken -User $Username

	Write-Verbose "getting all devices in Intune"
	$AllDevices = Get-MsGraphData "deviceManagement/managedDevices"

	# Get detected app for each device and check for app name
	[System.Collections.Generic.List[PSObject]]$FoundApp = @()
	$wp = 1
	Write-Verbose "querying devices for $Application $Version"
	foreach ($Device in $AllDevices) {
		if ($ShowProgress) { Write-Progress -Activity "Found $($FoundApp.count)" -Status "$wp of $($AllDevices.count)" -PercentComplete $(($wp/$($AllDevices.count))*100) -id 1 }
		$AppData = Get-MsGraphData "deviceManagement/managedDevices/$($Device.id)?`$expand=detectedApps"
		$DetectedApp = $AppData.detectedApps | Where-Object {$_.displayname -like $Application}
		if (![string]::IsNullOrEmpty($Version)) {
			$DetectedApp = $DetectedApp | Where-Object { $_.ProductVersion -eq $Version }
		}
		if ($DetectedApp) {
			$DetectedApp | 
				Select-Object @{l='DeviceName';e={$Device.DeviceName}}, @{l='Application';e={$_.displayname}}, Version, SizeInByte,
				@{l='LastSyncDateTime';e={$Device.lastSyncDateTime}}, @{l='DeviceId';e={$Device.id}} | 
					Foreach-Object { $FoundApp.Add($_) }
		}
		$wp++
	}
	if ($ShowProgress) { Write-Progress -Activity "Done" -Id 1 -Completed }
	$FoundApp
}

function Write-psIntuneDeviceReport {
	<#
	.SYNOPSIS
		Export Inventory Data to Excel Workbook
	.DESCRIPTION
		Export Intune Device inventory data to Excel Workbook
	.PARAMETER DataSet
		Device Data queried from Intune using Get-psIntuneDevice -Detail Full
		If DataSet is not provided, data will be queried from Intune.
	.PARAMETER OutputFolder
		Path for output file. Default is current user Documents path
	.PARAMETER Title
		Title to use for output filename
	.PARAMETER DeviceOS
		Filter devices by operating system. Options: Android, iOS, Windows, All
		Default is All
	.PARAMETER StaleLimit
		Number of days since last Intune synchronization to consider as a stale account
		Default is 180
	.PARAMETER LowDiskGB
		Free disk space GB to indicate "low disk space".
		Default is 20
	.PARAMETER AzureAD
		Includes AzureAD device accounts with report
	.PARAMETER Overwrite
		If output file exists, with same name, it will be overwritten.
		Default is to abort if idential filename exists.
	.PARAMETER Show
		Display workbook when export is complete. Default is to not show
	#>
	[CmdletBinding()]
	param (
		[parameter()] $DataSet,
		[parameter()][string] $OutputFolder = "$($env:USERPROFILE)\Documents",
		[parameter()][string] $Title = "",
		[parameter()][string][ValidateSet('All','Windows','Android','iOS')] $DeviceOS = 'All',
		[parameter()][ValidateRange(1,1000)][int] $StaleLimit = 180,
		[parameter()][ValidateRange(0,100)][int] $LowDiskGB = 20,
		[parameter()][switch] $AzureAD,
		[parameter()][switch] $Overwrite,
		[parameter()][switch] $Show
	)
	$time1 = Get-Date
	Write-Host "Gathering data to generate report"
	$xlFile = "$OutputFolder\IntuneDevices`_$Title`_$(Get-Date -f 'yyyy-MM-dd').xlsx"
	Write-Verbose "output file = $xlFile"
	if ((Test-Path $xlFile) -and (!$Overwrite)) {
		Write-Warning "Output file exists [$xlFile]. Use -Overwrite to replace."
		break
	}
	if ($null -eq $DataSet) {
		Write-Host "Requesting new query results..."
		$devs = Get-psIntuneDevice -Detail Full -ShowProgress
	}
	else {
		$devs = $DataSet
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
	$models    = $devs | Select-Object Manufacturer,Model | Group-Object -Property Manufacturer,Model | Select-Object Count,Name | Sort-Object Count -Descending
	Write-Host "Applying filter rule: Orphaned Devices"
	$deldevs   = $devs | Where-Object {$_.DeviceName -eq 'User deleted for this device'} | Select-Object * -ExcludeProperty Apps
	Write-Host "Applying filter rule: Duplicate Devices"
	$dupedevs  = $devs | Select-Object DeviceName,DeviceID | Group-Object -Property DeviceName | Select-Object Count,Name
	Write-Host "Applying filter rule: Stale Devices"
	$staledevs = $devs | Where-Object {$_.LastSyncDays -ge $StaleLimit} | Select-Object DeviceName,DeviceID,Category,Ownership,Manufacturer,Model,UserName,SerialNumber,LastSyncTime,LastSyncDays,EnrollDate
	Write-Host "Applying filter rule: Devices with Low Disk Space"
	$lowdisk   = $devs | Where-Object {$_.FreeSpaceGB -lt $LowDiskGB} | Select-Object * -ExcludeProperty Apps
	Write-Host "Applying filter rule: Software"
	$apps      = Get-psIntuneInstalledApps -DataSet $devs 
	Write-Host "Applying filter rule: Software Install Counts"
	$appcounts = $apps | Group-Object -Property ProductName | Select-Object Count,Name | Sort-Object Name -Unique
	Write-Host "Applying filter rule: Distinct Software Installs"
	$distapps  = $apps | Select-Object ProductName,ProductType,DeviceName | Sort-Object ProductName -Unique
	if ($AzureAD) {
		$aadevs = Get-psIntuneAzureADDevices
		if ($DeviceOS -ne 'All') {
			$aadevs = $aadevs | Where-Object { $_.OSName -match $DeviceOS }
			Write-Verbose "returned $($aadevs.Count) AzureAD devices running $DeviceOS"
		}
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
	}

	Write-Host "Exporting datasets: Summary"
	$stats | Export-Excel -Path $xlFile -WorksheetName "Summary" -ClearSheet -AutoSize -AutoFilter -FreezeTopRow
	Write-Host "Exporting datasets: Intune Devices"
	$intdevs | Export-Excel -Path $xlFile -WorksheetName "IntuneDevices" -ClearSheet -AutoSize -AutoFilter -FreezeTopRowFirstColumn
	if ($AzureAD) {
		Write-Host "Exporting datasets: AzureAD devices"
		$aadevs | Export-Excel -Path $xlFile -WorksheetName "AzureADDevices" -ClearSheet -AutoSize -AutoFilter -FreezeTopRowFirstColumn
	}
	Write-Host "Exporting datasets: Intune Device Models"
	$models | Export-Excel -Path $xlFile -WorksheetName "IntuneModels" -ClearSheet -AutoSize -AutoFilter -FreezeTopRow
	Write-Host "Exporting datasets: Intune Stale Devices"
	$staledevs | Export-Excel -Path $xlFile -WorksheetName "IntuneStaleDevices" -ClearSheet -AutoSize -AutoFilter -FreezeTopRowFirstColumn
	Write-Host "Exporting datasets: Intune Duplicate Devices"
	$dupedevs | Export-Excel -Path $xlFile -WorksheetName "IntuneDuplicates" -ClearSheet -AutoSize -AutoFilter -FreezeTopRow
	Write-Host "Exporting datasets: Intune Orphaned Devices"
	$deldevs | Export-Excel -Path $xlFile -WorksheetName "IntuneOrphaned" -ClearSheet -AutoSize -AutoFilter -FreezeTopRowFirstColumn
	Write-Host "Exporting datasets: Intune Devices with Low Disk Space"
	$lowdisk | Export-Excel -Path $xlFile -WorksheetName "IntuneLowDisk" -ClearSheet -AutoSize -AutoFilter -FreezeTopRowFirstColumn
	Write-Host "Exporting datasets: Intune Installed Software"
	$apps | Export-Excel -Path $xlFile -WorksheetName "IntuneSoftware" -ClearSheet -AutoSize -AutoFilter -FreezeTopRowFirstColumn
	Write-Host "Exporting datasets: Intune Software Install Counts"
	$appcounts | Export-Excel -Path $xlFile -WorksheetName "IntuneInstallCounts" -ClearSheet -AutoSize -AutoFilter -FreezeTopRow
	Write-Host "Exporting datasets: Intune Software Unique Instances"
	$distapps | Export-Excel -Path $xlFile -WorksheetName "IntuneSoftwareUnique" -ClearSheet -AutoSize -AutoFilter -FreezeTopRow

	if ($Show) { Start-Process -FilePath "$xlFile" }
	Write-Host "Export saved to $xlFile" -ForegroundColor Green

	$time2 = Get-Date
	$rt = New-TimeSpan -Start $time1 -End $time2
	Write-Host "Total runtime: $($rt.Hours)`:$($rt.Minutes)`:$($rt.Seconds) (hh`:mm`:ss)" -ForegroundColor Cyan
}

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
		https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Invoke-psIntuneAppQuery.md

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

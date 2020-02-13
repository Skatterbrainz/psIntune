<#
.COPYRIGHT
Portions of this are derived from Microsoft content on GitHub at the following URL:

https://github.com/microsoftgraph/powershell-intune-samples/blob/master/ManagedDevices/ManagedDevices_Apps_Get.ps1

Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.
#>

#region Microsoft GitHub sample code

$graphApiVersion = "beta"

function Get-AuthToken {
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

function Get-DsIntuneAuth {
	<#
	.SYNOPSIS
		Returns authentication token object
	.PARAMETER UserName
		UserName for cloud services access
	.EXAMPLE
		Get-DsIntuneAuth -UserName "john.doe@contoso.com"
	.NOTES
		Name: Get-DsIntuneAuth
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

Function Get-DsIntuneAzureADUser() {
	<#
	.SYNOPSIS
		This function is used to get AAD Users from the Graph API REST interface
	.DESCRIPTION
		The function connects to the Graph API Interface and gets any users registered with AAD
	.EXAMPLE
		Get-DsIntuneAzureADUser
		Returns all users registered with Azure AD
	.EXAMPLE
		Get-DsIntuneAzureADUser -userPrincipleName user@domain.com
		Returns specific user by UserPrincipalName registered with Azure AD
	.NOTES
		NAME: Get-DsIntuneAzureADUser
	.LINK
		https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-DsIntuneAzureADUser.md
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

function Get-DsIntuneAzureADDevices {
	<#
	.SYNOPSIS
		Return AzureAD device accounts
	.DESCRIPTION
		Return all AzureAD tenant device accounts
	.EXAMPLE
		Get-DsIntuneAzureADDevices
	.NOTES
		Name: Get-DsIntuneAzureADDevices
	.LINK
		https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-DsIntuneAzureADDevices.md
	#>
	[CmdletBinding()]
	param()
	if (!$AADCred) { $Global:AADCred = Connect-AzureAD }
	Write-Verbose "requesting devices from Azure AD tenant"
	$aadcomps = Get-AzureADDevice -All $True
	Write-Verbose "returned $($aadcomps.Count) devices from Azure AD"
	$aadcomps | Foreach-Object {
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
			Name           = $_.DisplayName
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

Function Get-MsGraphData($Path) {
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

Function Get-ManagedDevices(){
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
		[parameter()][switch] $IncludeEAS,
		[parameter()][switch] $ExcludeMDM
	)
	#$graphApiVersion = "beta"
	$Resource = "deviceManagement/managedDevices"
	try {
		Get-DsIntuneAuth -UserName $UserName
		$Count_Params = 0
		if ($IncludeEAS.IsPresent){ $Count_Params++ }
		if ($ExcludeMDM.IsPresent){ $Count_Params++ }
		if ($Count_Params -gt 1) {
			Write-Warning "Multiple parameters set, specify a single parameter -IncludeEAS, -ExcludeMDM or no parameter against the function"
			#Write-Host
			break
		}
		elseif ($IncludeEAS) {
			$uri = "https://graph.microsoft.com/$graphApiVersion/$Resource"
		}
		elseif ($ExcludeMDM) {
			$uri = "https://graph.microsoft.com/$graphApiVersion/$Resource`?`$filter=managementAgent eq 'eas'"
		}
		else {
			$uri = "https://graph.microsoft.com/$graphApiVersion/$Resource`?`$filter=managementAgent eq 'mdm' and managementAgent eq 'easmdm'"
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

function Get-DsIntuneDevices {
	<#
	.SYNOPSIS
		Returns dataset of Intune-managed devices with inventoried apps

	.DESCRIPTION
		Returns dataset of Intune-managed devices with inventoried apps

	.PARAMETER UserName
		UserPrincipalName for authentication request

	.PARAMETER ShowProgress
		Display progress as data is exported (default is silent / no progress shown)

	.PARAMETER Detailed
		Optional expanded list of device properties which includes:
		* DeviceName, DeviceID, Manufacturer, Model, MemoryGB, DiskSizeGB, FreeSpaceGB,	EthernetMAC, 
		  SerialNumber, OSName, OSVersion, Ownership, Category, LastSyncTime, UserName, Apps
		* The default return property set: DeviceName, DeviceID, OSName, OSVersion, LastSyncTime, UserName, Apps
		* Note that for either case, Apps will be set to $null if parameter -NoApps is used

	.PARAMETER NoApps
		Exclude installed Applications data from return dataset
		This reduces overall query time significantly!

	.EXAMPLE
		$devices = Get-DsIntuneDevices -UserName "john.doe@contoso.com"

		Returns results of online request to variable $devices

	.EXAMPLE
		$devices = Get-DsIntuneDevices -UserName "john.doe@contoso.com" -ShowProgress

		Returns results of online request to variable $devices while displaying concurrent progress

	.EXAMPLE
		$devices = Get-DsIntuneDevices -UserName "john.doe@contoso.com" -Detailed -NoApps

		Returns detailed results of online request to variable $devices without installed applications data

	.EXAMPLE
		$devices = Get-DsIntuneDevices -UserName "john.doe@contoso.com" -NoApps

		Returns summary results of online request to variable $devices without installed applications data
		This is the fastest query option of all the parameter options

	.NOTES
		NAME: Get-DsIntuneDevices

	.LINK
		https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-DsIntuneDevices.md

	#>
	[CmdletBinding()]
	param(
		[parameter(Mandatory)][string] $UserName,
		[parameter()][switch] $ShowProgress,
		[parameter()][switch] $Detailed,
		[parameter()][switch] $NoApps
	)
	#if ($UserName) { Get-DsIntuneAuth -UserName $UserName } else { Get-DsIntuneAuth }
	$Devices = Get-ManagedDevices -UserName $UserName
	Write-Host "returned $($Devices.Count) managed devices"
	if ($Devices) {
		if ($Detailed) {
			Write-Host "getting detailed device properties (this may take a few minutes)..."
		}
		else {
			Write-Host "getting device properties..."
		}
		$dx = 1
		$dcount = $Devices.Count
		foreach ($Device in $Devices){
			if ($ShowProgress) { 
				Write-Progress -Activity "Found $dcount" -Status "$dx of $dcount" -PercentComplete $(($dx/$dcount)*100) -id 1
			}
			$DeviceID = $Device.id
			$uri = "https://graph.microsoft.com/$graphApiVersion/deviceManagement/manageddevices('$DeviceID')?`$expand=detectedApps"
			if (!$NoApps) { 
				$DetectedApps = (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).detectedApps 
			}
			$dx++
			$LastSync = $Device.lastSyncDateTime
			$SyncDays = (New-TimeSpan -Start $LastSync -End (Get-Date)).Days
			
			if ($Detailed) {
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
			else {
				[pscustomobject]@{
					DeviceName   = $Device.DeviceName
					DeviceID     = $DeviceID
					UserName     = $Device.userDisplayName
					OSName       = $Device.operatingSystem 
					OSVersion    = $Device.osVersion
					LastSyncTime = $LastSync
					LastSyncDays = $SyncDays
					Apps         = $DetectedApps
				}
			}
		}
	}
	else {
		Write-Host "No Intune Managed Devices found..." -f green
		Write-Host
	}
}

function Get-DsIntuneDevicesRaw {
	<#
	.SYNOPSIS
		Returns raw data for all Intune devices

	.DESCRIPTION
		Returns raw data for all Intune devices

	.EXAMPLE
		$allDevices = Get-DsIntuneDevicesRaw

	.NOTES
		NAME: Get-DsIntuneDevicesRaw
		Alias for Get-ManagedDevices()

	.LINK
		https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-DsIntuneDevicesRaw.md

	#>
	[CmdletBinding()]
	param ()
	Get-ManagedDevices
}

function Get-DsIntuneDeviceSummary {
	<#
	.SYNOPSIS
		Returns Summary by Property Set

	.DESCRIPTION
		Returns grouped data by property set

	.PARAMETER Property
		Name of device property to group dataset on. Default is OSName

	.PARAMETER DataSet
		Devices dataset returned from Get-DsIntuneDevices

	.PARAMETER UserName
		Required for invoked query if DataSet is $null

	.PARAMETER ShowProgress
		Show progress indicator while querying dataset

	.EXAMPLE
		$devices = Get-DsIntuneDevices -UserName "john.doe@contoso.com"
		Get-DsIntuneDeviceSummary -DataSet $devices -Property Model -ShowProgress

		Query against data returned from direct query and saved to $devices

	.EXAMPLE
		Get-DsIntuneDeviceSummary -Property Model -UserName "john.doe@contoso.com" -ShowProgress

		Query data directly from Intune graph source

	.NOTES
		Name: Get-DsIntuneDeviceSummary

	.LINK
		https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-DsIntuneDeviceSummary.md

	#>
	[CmdletBinding()]
	param (
		[parameter()][ValidateSet('OSName','Model','Manufacturer','ComplianceState','AutoPilotEnrolled','Ownership')] $Property = 'OSName',
		[parameter()] $DataSet,
		[parameter()][string] $UserName,
		[parameter()][switch] $ShowProgress
	)
	if ($null -eq $DataSet) {
		$DataSet = Get-DsIntuneDevices -UserName $UserName -Detailed -ShowProgress:$ShowProgress -NoApps
	}
	$DataSet | 
		Where-Object {![string]::IsNullOrEmpty($_."$Property")} |
			Select-Object DeviceName,$Property |
				Sort-Object DeviceName -Unique |
					Group-Object $Property |
						Select-Object Count,Name
}

function Get-DsIntuneStaleDevices {
	<#
	.SYNOPSIS
		Returns devices which have not synchronized within the last N (-Days)

	.DESCRIPTION
		Returns Intune device accounts which have not synchronized within
		the last <N> days as specified by -Days

	.PARAMETER DataSet
		Data returned from Get-DsIntuneDeviceData()

	.PARAMETER Days
		Number of days to allow, from 1 to 1000 (default is 30)

	.PARAMETER Detailed
		Returns detailed property set for each device (see Get-DsIntuneDeviceData) if -DataSet is $null

	.PARAMETER ShowProgress
		Displays progress during query if -DataSet is $null

	.EXAMPLE
		Get-DsIntuneStaleDevices -DataSet $devices

		Returns devices which have not synchronized with AzureAD in the last 30 days

	.EXAMPLE
		Get-DsIntuneStaleDevices -DataSet $devices -Detailed -Days 60

		Returns devices with detailed properties which have not synchronized with AzureAD in the last 60 days

	.NOTES
		NAME: Get-DsIntuneStaleDevices

	.LINK
		https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-DsIntuneStaleDevices.md
	#>
	[CmdletBinding()]
	param (
		[parameter()] $DataSet,
		[parameter()][string] $UserName,
		[parameter()][ValidateRange(1,1000)][int] $Days = 30,
		[parameter()][switch] $Detailed,
		[parameter()][switch] $ShowProgress
	)
	try {
		if (!$DataSet) {
			Write-Host "querying Intune devices" -ForegroundColor Cyan
			$DataSet = Get-DsIntuneDevices -UserName $UserName -ShowProgress:$ShowProgress -Detailed:$Detailed -NoApps
		}
		else {
			Write-Verbose "re-querying $($DataSet.Count) devices from existing dataset"			
		}
		$result = $DataSet | Where-Object {($null -eq $_.LastSyncTime) -or $(New-TimeSpan -Start $_.LastSyncTime -End (Get-Date)).Days -gt $Days}
	}
	catch {
		Write-Error $_.Exception.Message
	}
	finally {
		$result
	}
}

function Get-DsIntuneInstalledApps ($DataSet) {
	<#
	.SYNOPSIS
		Returns App inventory data from Intune Device data set

	.DESCRIPTION
		Returns App inventory data from Intune Device data set

	.PARAMETER DataSet
		Data returned from Get-DsIntuneDevices()

	.EXAMPLE
		$devices = Get-DsIntuneDevices -UserName "john.doe@contoso.com"
		$applist = Get-DsIntuneDeviceApps -DataSet $devices

	.NOTES
		NAME: Get-DsIntuneInstalledApps

	.LINK
		https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-DsIntuneInstalledApps.md

	#>
	if (!$DataSet) {
		Write-Warning "device accounts dataset from Get-DsIntuneDevices required"
		break
	}
	$badnames = ('. .','. . .','..','...')
	foreach ($row in $Dataset) {
		$devicename = $row.DeviceName
		if ($null -ne $row.Apps) {
			$apps = $row.Apps
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
		}
	}
}

function Get-DsIntuneDevicesWithApp {
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
		Get-DsIntuneDevicesWithApp -Application "*Putty*" -UserName "john.doe@contoso.com"

		Returns list of Intune-managed devices which have any app name containing "Putty" installed

	.EXAMPLE
		Get-DsIntuneDevicesWithApp -Application "*Putty*" -UserName "john.doe@contoso.com" -ShowProgress

		Returns list of Intune-managed devices which have any apps name containing "Putty" installed, and displays progress during execution

	.NOTES
		NAME: Get-DsIntuneDevicesWithApp
		This function was derived almost entirely from https://www.dowst.dev/search-intune-for-devices-with-application-installed/
		(Thanks to Matt Dowst)

	.LINK
		https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-DsIntuneDevicesWithApp.md

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

function Get-DsIntuneInstalledAppCounts {
	<#
	.SYNOPSIS
		Return Applications grouped and sorted by Installation Counts

	.DESCRIPTION
		Return Applications grouped and sorted by Installation Counts in descending order

	.PARAMETER AppDataSet
		Applications dataset returned from Get-DsIntuneInstalledApps()

	.PARAMETER RowCount
		Limit to first (N) rows (default is 0 / returns all rows)

	.EXAMPLE
		$apps = Get-DsIntuneInstalledApps -DataSet $devices
		$top20 = Get-DsIntuneInstalledAppCounts -AppDataSet $apps -RowCount 20

	.NOTES
		NAME: Get-DsIntuneInstalledAppCounts

	.LINK
		https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-DsIntuneInstalledAppCounts.md

	#>
	param (
		[parameter()] $AppDataSet,
		[parameter()][int] $RowCount = 0
	)
	try {
		$result = $AppDataSet | Group-Object -Property ProductName,ProductVersion | Select-Object Count,Name | Sort-Object Count -Descending
		if ($RowCount -gt 0) { 
			$result | Select-Object -First $RowCount
		}
		else {
			$result
		}
	}
	catch {
		Write-Error $_.Exception.Message
	}
}

function Export-DsIntuneInventory {
	<#
	.SYNOPSIS
		Export Intune Device Applications Inventory to Excel Workbook

	.DESCRIPTION
		Export Intune Device Applications Inventory to Excel Workbook

	.PARAMETER DeviceData
		Device data returned from Get-DsIntuneDeviceData(). If not provided, Get-DsIntuneDeviceData() is invoked automatically.
		Passing Device data to -DeviceData can save significant processing time.

	.PARAMETER Title
		Title used for prefix of XLSX filename

	.PARAMETER UserName
		UserPrincipalName for authentication

	.PARAMETER Overwrite
		Replace output file it exists

	.PARAMETER DaysOld
		Filter stale accounts by specified number of days (range 10 to 1000, default = 180)

	.PARAMETER Show
		Open workbook in Excel when completed (requires Excel on host machine)

	.PARAMETER Distinct
		Filter DeviceName+AppName only to remove duplicates arising from different versions

	.PARAMETER DeviceOS
		Filter devices and derivative datasets to specified OS. 
		Options include: Windows, iOS, Android, or All. Default is 'All'

	.EXAMPLE
		Export-DsIntuneInventory -Title "Contoso" -UserName "john.doe@contoso.com" -Overwrite

		Queries all Intune devices and applications to generate output file

	.EXAMPLE
		$devices = Get-DsIntuneDevices -UserName "john.doe@contoso.com"
		$apps = Get-DsIntuneInstalledApps -DataSet $devices

		Export-DsIntuneInventory -DeviceData $devices -Title "Contoso" -UserName "john.doe@contoso.com" -Overwrite -Show
		
		Processes existing data ($devices) to generate output file with "Contoso" in the filename, and 
		display the results in Excel when finished
	
	.EXAMPLE
		$devices = Get-DsIntuneDevices -UserName "john.doe@contoso.com"
		$apps = Get-DsIntuneInstalledApps -DataSet $devices
		Export-DsIntuneInventory -DeviceData $devices -Title "Contoso" -UserName "john.doe@contoso.com" -Overwrite -Show -Distinct
		
		Processes existing data ($devices) to generate output file with "Contoso" in the filename, and 
		display the unique App results in Excel when finished

	.EXAMPLE
		$devices = Get-DsIntuneDevices -UserName "john.doe@contoso.com" | Where-Object {$_.OSName -eq 'Windows'}
		$apps = Get-DsIntuneInstalledApps -DataSet $devices
		Export-DsIntuneInventory -DeviceData $devices -Title "Contoso" -UserName "john.doe@contoso.com" -Overwrite -Show -Distinct
		
		Processes existing data ($devices) for only Windows devices, to generate output file with "Contoso" in the
		filename, and display the unique App results in Excel when finished

	.EXAMPLE
		$devices = Get-DsIntuneDevices -UserName "john.doe@contoso.com" -DeviceOS 'Windows'
		$apps = Get-DsIntuneInstalledApps -DataSet $devices
		Export-DsIntuneInventory -DeviceData $devices -Title "Contoso" -UserName "john.doe@contoso.com" -Overwrite -Show -Distinct
		
		Processes existing data ($devices) for only Windows devices, to generate output file with "Contoso" in the
		filename, and display the unique App results in Excel when finished

	.NOTES
		NAME: Export-DsIntuneInventory
		Requires PS module ImportExcel

	.LINK
		https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Export-DsIntuneInventory.md
	#>
	[CmdletBinding()]
	param (
		[parameter()] $DeviceData,
		[parameter()][string] $OutputFolder = "$($env:USERPROFILE)\Documents",
		[parameter(Mandatory)][ValidateNotNullOrEmpty()][string] $Title,
		[parameter()][ValidateNotNullOrEmpty()][string] $UserName,
		[parameter()][switch] $Overwrite,
		[parameter()][switch] $Distinct,
		[parameter()][int][ValidateRange(10,1000)] $DaysOld = 180,
		[parameter()][string][ValidateSet('All','Windows','Android','iOS')] $DeviceOS = 'All',
		[parameter()][switch] $Show
	)
	if (!(Get-Module ImportExcel -ListAvailable)) {
		Write-Warning "This function requires the PowerShell module ImportExcel, which is not installed."
		break
	}
	if ($null -eq $DeviceData) {
		if ([string]::IsNullOrEmpty($UserName)) {
			Write-Warning "UserName must be provided when DeviceData is not provided."
			break
		}
	}
	try {
		$time1 = Get-Date
		$xlFile = "$OutputFolder\$Title`_IntuneDevices_$(Get-Date -f 'yyyy-MM-dd').xlsx"
		Write-Verbose "output file = $xlFile"
		if ((Test-Path $xlFile) -and (!$Overwrite)) {
			Write-Warning "Output file exists [$xlFile]. Use -Overwrite to replace."
			break
		}
		if (!$DeviceData) {
			Write-Host "Requesting managed devices data from Intune" -ForegroundColor Cyan
			$DeviceData = Get-DsIntuneDevices -UserName $UserName -Detailed
		}
		else {
			Write-Warning "Device dataset should be derived with [-Detailed] option, to get the full set of properties."
		}
		if ($DeviceOS -ne 'All') {
			Write-Host "Filtering Intune devices by OSName: $DeviceOS"
			$DeviceData = $DeviceData | Where-Object {$_.OSName -eq $DeviceOS}
			Write-Host "Returned $($DeviceData.Count) devices running $DeviceOS"
		}
		Write-Host "Querying: installed applications for each device"
		$applist = Get-DsIntuneInstalledApps -DataSet $DeviceData
		if ($Distinct) {
			Write-Host "Filtering: unique product names per device"
			$applist2 = $applist | Select-Object DeviceName,ProductName | Sort-Object ProductName,DeviceName -Unique
		}

		Write-Host "Querying: AzureAD devices (you may be prompted for credentials)" -ForegroundColor Green
		$aaddevices  = Get-DsIntuneAzureADDevices
		Write-Host "Found $($aaddevices.Count) AzureAD device accounts"
		if ($DeviceOS -ne 'All') {
			Write-Host "Filtering AzureAD devices by OSName: $DeviceOS"
			$aaddevices = $aaddevices | Where-Object {$_.OSName -match $DeviceOS}
			Write-Host "Returned $($aaddevices.Count) AzureAD devices running $DeviceOS"
		}

		Write-Host "Querying: Stale devices (more than $DaysOld days)"
		$stale = Get-DsIntuneStaleDevices -DataSet $DeviceData -Days $DaysOld
		Write-Host "Found $($stale.Count) devices not synchronized in the last $DaysOld days"

		Write-Host "Crunching statistics and stuff..."
		$stats = @()
		$stats += $aawin | Group-Object -Property IsCompliant | Select-Object Name,Count | % {[pscustomobject]@{Name = 'Compliant'; Property = $_.Name; Value = $_.Count}}
		$stats += $aawin | Group-Object -Property DirSyncEnabled | Select-Object Name,Count | % {[pscustomobject]@{Name = 'DirSyncEnabled'; Property = $_.Name; Value = $_.Count}}
		$stats += $aawin | Group-Object -Property TrustType | Select-Object Name,Count | % {[pscustomobject]@{Name = 'TrustType'; Property = $_.Name; Value = $_.Count}}
		$stats += $aawin | Group-Object -Property OSVersion | Select-Object Name,Count | ?{$_.Name -ne '' -and $_.Count -gt 5} | Sort-Object Count -Descending | % {[pscustomobject]@{Name = 'OSVersion'; Property = $_.Name; Value = $_.Count}}
		$stats += $aadevs | Group-Object -Property LastLogonDays | ?{$_.Name -gt 180 -and $_.Count -gt 10} | %{[pscustomobject]@{Name = 'DaysSinceLogon'; Count = $_.Count; Property = [int]$_.Name}} | Sort-Object Property -Descending
		$stats += $devices | Group-Object -Property Manufacturer,Model | Select-Object Name,Count | Sort-Object Count -Descending | %{[pscustomobject]@{Name = 'Models'; Property = $_.Name; Value = $_.Count}}
		$stats += $devices | Group-Object -Property Ownership | Select-Object Name,Count | Sort-Object Count -Descending | %{[pscustomobject]@{Name = 'Ownership'; Property = $_.Name; Value = $_.Count}}
		$stats += $devices | Group-Object -Property Category | Select-Object Name,Count | Sort-Object Count -Descending | %{[pscustomobject]@{Name = 'Category'; Property = $_.Name; Value = $_.Count}}
		$stats += $devices | Group-Object -Property UserName | Select-Object Name,Count | Where-Object {$_.Count -gt 1 -and $_.Name -ne ''} | Sort-Object Count -Descending | Select-Object -First 25 | %{[pscustomobject]@{Name = 'UserName'; Property = $_.Name; Value = $_.Count}}

		Write-Host "Exporting data to workbook..."
		$stats |
			Export-Excel -Path $XlFile -WorksheetName "Summary" -ClearSheet -AutoSize -FreezeTopRow -AutoFilter
		$aaddevices | 
			Export-Excel -Path $xlFile -WorksheetName "AADDevices" -ClearSheet -AutoSize -FreezeTopRowFirstColumn -AutoFilter
		$DeviceData | Where-Object {$_.DeviceName -ne 'User deleted for this device'} | 
			Select-Object * -ExcludeProperty Apps | Sort-Object DeviceName -Unique |
				Export-Excel -Path $xlFile -WorksheetName "IntuneDevices" -ClearSheet -AutoSize -FreezeTopRow -AutoFilter
		$stale | Select-Object * -ExcludeProperty Apps |	
			Export-Excel -Path $XlFile -WorksheetName "StaleDevices" -ClearSheet -AutoSize -FreezeTopRow -AutoFilter 
		$DeviceData | Where-Object {$_.DeviceName -eq 'User deleted for this device'} | 
			Select-Object * -ExcludeProperty Apps | Sort-Object DeviceName,Manufacturer,Model |
				Export-Excel -Path $xlFile -WorksheetName "UserDeletedDevices" -ClearSheet -AutoSize -FreezeTopRow -AutoFilter
		$DeviceData | Where-Object {$_.FreeSpaceGB -lt 20 -and $_.OSName -eq 'Windows'} |
			Select-Object * -ExcludeProperty Apps | Sort-Object DeviceName,Manufacturer,Model |
				Export-Excel -Path $xlFile -WorksheetName "LowDisk" -ClearSheet -AutoSize -FreezeTopRow -AutoFilter
		$applist | 
			Sort-Object ProductName |
				Export-Excel -Path $xlFile -WorksheetName "IntuneApps" -ClearSheet -AutoSize -FreezeTopRow -AutoFilter
		if ($null -ne $applist2) {
			$applist2 | Sort-Object ProductName,ProductVersion |
				Export-Excel -Path $xlFile -WorksheetName "DistinctApps" -ClearSheet -AutoSize -FreezeTopRow -AutoFilter
		}

		Write-Host "Results saved to: $xlFile" -ForegroundColor Green
		$time2 = Get-Date
		$rt = New-TimeSpan -Start $time1 -End $time2
		Write-Host "Total runtime: $($rt.Hours)`:$($rt.Minutes)`:$($rt.Seconds) (hh`:mm`:ss)" -ForegroundColor Cyan
		if ($Show) { Start-Process -FilePath "$xlFile" }
	}
	catch {
		Write-Error $_.Exception.Message
	}
}

function Invoke-DsExcelQuery {
	<#
	.SYNOPSIS
		Query Excel Workbook/WorkSheet using SQL statement

	.DESCRIPTION
		Same as above

	.PARAMETER FilePath
		Path and filename to .xlsx workbook file

	.PARAMETER Query
		SQL query statement

	.EXAMPLE
		$xlFile = "c:\myfiles\IntuneDeviceData.xlsx"
		$query = "select DeviceName,ProductName from [IntuneApps$] where ProductName='Crapware 2019'"
		$rows = Invoke-DsExcelQuery -FilePath $xlFile -Query $query

	.NOTES
		NAME: Invoke-DsExcelQuery

	.LINK
		https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Invoke-DsExcelQuery.md
	#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory)][ValidateNotNullOrEmpty()][string] $FilePath,
		[parameter(Mandatory)][ValidateNotNullOrEmpty()][string] $Query
	)
	if (-not(Test-Path $FilePath)) {
		Write-Warning "file not found: $FilePath"
		break
	}
	try {
		$conn = New-Object System.Data.OleDb.OleDbConnection
		$cmd  = New-Object System.Data.OleDb.OleDbCommand

		$connstr = "Provider=Microsoft.ACE.OLEDB.12.0;Data Source=$FilePath;Extended Properties='Excel 12.0 Xml;HDR=YES;'"
		$conn.ConnectionString = $connstr

		$conn.Open()
		#$conn.GetSchema("tables")
		$cmd.CommandText = $query
		$cmd.CommandType = "Text"
		$cmd.Connection = $conn

		$dataReader = $cmd.ExecuteReader()
		$result = @()
		while ($dataReader.Read()) {
			$columns = $($dataReader.GetSchemaTable()).ColumnName
			$row = New-Object PSObject
			foreach ($column in $columns) {
				$row | Add-Member -MemberType NoteProperty -Name $column -Value $dataReader.item($column)
			}
			$result += $row
		}
	}
	catch {
		Write-Error $_.Exception.Message
	}
	finally {
		$conn.Close()
		$result
	}
}

function Invoke-DsIntuneAppQuery {
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
		$rows = Invoke-DsIntuneAppQuery -AppDataSet $applist -ProductName "Acme Crapware 19.20 64-bit"

	.NOTES
		NAME: Invoke-DsIntuneAppQuery

	.LINK
		https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Invoke-DsIntuneAppQuery.md

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

function Test-DsIntuneUpdate {
	<#
	.SYNOPSIS
		Compare installed module version with latest in PS Gallery

	.DESCRIPTION
		Compare installed module version with latest in PS Gallery

	.EXAMPLE
		Test-DsIntuneUpdate

	.NOTES
		NAME: Test-DsIntuneUpdate

	.LINK
		https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Test-DsIntuneUpdate.md

	#>
	[CmdletBinding()]
	param()
	try {
		$chkver = (Find-Module "ds-intune").Version
		$insver = ((Get-Module "ds-intune" | Sort-Object version -Descending).Version)[0] -join '.'
		if ($insver -lt $chkver) {
			Write-Warning "ds-intune $insver is installed. Latest version is $chkver. Use Update-Module ds-intune to update."
		}
		else {
			Write-Host "ds-intune $insver is installed. Latest version is $chkver." -ForegroundColor Green
		}
	}
	catch {
		Write-Host "(ds-intune) unable to check for module updates."
		Write-Error $_.Exception.Message
	}
}

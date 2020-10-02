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
		[parameter(Mandatory)][ValidateNotNull()] $DataSet,
		[parameter()][boolean] $GroupByName = $False
	)
	$badnames = ('. .','. . .','..','...')
	Write-Verbose "reading $($DataSet.Count) objects"
	[int]$appcount = 0
	$result = $DataSet | Foreach-Object {
		[string]$devicename = $_.DeviceName
		$apps = $_.Apps 
		if ($null -ne $Apps) {
			foreach ($app in $apps) {
				$displayName = $($app.displayName).ToString().Trim()
				if (![string]::IsNullOrEmpty($displayName)) {
					if ($displayName -notin $badnames) {
						if ($($app.Id).Length -gt 36) {
							[string]$ptype = 'WindowsStore'
						}
						elseif ($($app.Id).Length -eq 36) {
							[string]$ptype = 'Win32'
						}
						else {
							[string]$ptype = 'Other'
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
	if ($GroupByName -eq $True) {
		$result | Group-Object -Property ProductName | Select-Object Count,Name | Sort-Object Name -Unique
	}
	else {
		$result
	}
}
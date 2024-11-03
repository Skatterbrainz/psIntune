function New-PsIntuneDeviceReport {
	<#
	.SYNOPSIS
		Quick Report version of Write-PsIntuneDeviceReport
	.DESCRIPTION
		Yeah. What he said
	.PARAMETER UserName
		User account to use for AzureAD and Intune tenant
	.PARAMETER ReportName
		Title to include in the report filename
	.PARAMETER DeviceOS
		Filter devices by operating system. Options: Android, iOS, Windows, All. Default is All
	.PARAMETER OutputFolder
		Path for output file. Default is current user Documents path
	.PARAMETER Show
		Open results in Excel (if Excel is installed on the machine where script is executed)
	.EXAMPLE
		New-PsIntuneDeviceReport -UserName "john@contoso.com" -ReportName "Contoso" -DeviceOS 'Windows'
	.LINK
		https://github.com/Skatterbrainz/psIntune/blob/master/docs/New-PsIntuneDeviceReport.md
	#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory)][ValidateNotNullOrEmpty()][string] $UserName,
		[parameter(Mandatory)][ValidateNotNullOrEmpty()][string] $ReportName,
		[parameter()][string][ValidateSet('All','Windows','Android','iOS')] $DeviceOS = 'All',
		[parameter()][string] $OutputFolder = "$([System.Environment]::GetFolderPath('Personal'))",
		[parameter()][boolean] $Show = $False
	)
	try {
		Write-Host "collecting Intune device hardware information..."
		$devs = Get-psIntuneDevice -UserName $UserName -Detail Detailed -DeviceOS $DeviceOS -ShowProgress:$True

		Write-Host "collecting Azure AD device inventory..."
		$adevs = Get-psIntuneAzureADDevices -UserName $UserName -ShowProgress:$True
		
		Write-Host "collecting Intune device software inventory..."
		$apps = Get-psIntuneDeviceApps -Devices $devs -UserName $UserName -ShowProgress:$True
		
		Write-Host "publishing inventory report..."
		Write-psIntuneDeviceReport -IntuneDevices $devs -IntuneApps $apps -AadDevices $adevs -OutputFolder $OutputFolder -ReportName $ReportName -DeviceOS $DeviceOS -Overwrite:$True -Show:$Show
	} catch {
		Write-Error $_.Exception.Message 
	}
}
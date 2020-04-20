# psIntune
Intune PowerShell Stuff

## Installation

```powershell
Install-Module psIntune
```

## Examples

### Gather Devices with Hardware Inventory Details

```powershell
$username = "betty.smith@contoso.com"
$devices = Get-PsIntuneDevice -UserName $username -DeviceOS Windows -Detail Detailed -ShowProgress
```

### Gather Installed Software Inventory for Devices

```powershell
$apps = Get-PsIntuneDeviceApps -UserName $username -ShowProgress
```

### Write Inventory Data to Excel Spreadsheet

```powershell
Write-psIntuneDeviceReport -Devices $devices -Apps $apps -Title "Contoso" -DeviceOS "Windows" -AzureAD -Overwrite -Show
```

There are more options/parameters for each of these commands, and there are more commands in the module as well.

### More Details

See documentation under [Docs](https://github.com/Skatterbrainz/psIntune/tree/master/docs) folder

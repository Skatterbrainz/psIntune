---
external help file: psIntune-help.xml
Module Name: psIntune
online version: https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Export-psIntuneInventory.md
schema: 2.0.0
---

# Export-psIntuneInventory

## SYNOPSIS
Export Intune Device Applications Inventory to Excel Workbook

## SYNTAX

```
Export-psIntuneInventory [[-DeviceData] <Object>] [[-OutputFolder] <String>] [-Title] <String>
 [[-UserName] <String>] [-Overwrite] [-Distinct] [[-DaysOld] <Int32>] [[-DeviceOS] <String>] [-Show]
 [<CommonParameters>]
```

## DESCRIPTION
Export Intune Device Applications Inventory to Excel Workbook

## EXAMPLES

### EXAMPLE 1
```
Export-psIntuneInventory -Title "Contoso" -UserName "john.doe@contoso.com" -Overwrite
```

Queries all Intune devices and applications to generate output file

### EXAMPLE 2
```
$devices = Get-psIntuneDevices -UserName "john.doe@contoso.com"
```

$apps = Get-psIntuneInstalledApps -DataSet $devices

Export-psIntuneInventory -DeviceData $devices -Title "Contoso" -UserName "john.doe@contoso.com" -Overwrite -Show

Processes existing data ($devices) to generate output file with "Contoso" in the filename, and 
display the results in Excel when finished

### EXAMPLE 3
```
$devices = Get-psIntuneDevices -UserName "john.doe@contoso.com"
```

$apps = Get-psIntuneInstalledApps -DataSet $devices
Export-psIntuneInventory -DeviceData $devices -Title "Contoso" -UserName "john.doe@contoso.com" -Overwrite -Show -Distinct

Processes existing data ($devices) to generate output file with "Contoso" in the filename, and 
display the unique App results in Excel when finished

### EXAMPLE 4
```
$devices = Get-psIntuneDevices -UserName "john.doe@contoso.com" | Where-Object {$_.OSName -eq 'Windows'}
```

$apps = Get-psIntuneInstalledApps -DataSet $devices
Export-psIntuneInventory -DeviceData $devices -Title "Contoso" -UserName "john.doe@contoso.com" -Overwrite -Show -Distinct

Processes existing data ($devices) for only Windows devices, to generate output file with "Contoso" in the
filename, and display the unique App results in Excel when finished

### EXAMPLE 5
```
$devices = Get-psIntuneDevices -UserName "john.doe@contoso.com" -DeviceOS 'Windows'
```

$apps = Get-psIntuneInstalledApps -DataSet $devices
Export-psIntuneInventory -DeviceData $devices -Title "Contoso" -UserName "john.doe@contoso.com" -Overwrite -Show -Distinct

Processes existing data ($devices) for only Windows devices, to generate output file with "Contoso" in the
filename, and display the unique App results in Excel when finished

## PARAMETERS

### -DeviceData
Device data returned from Get-DsIntuneDeviceData().
If not provided, Get-DsIntuneDeviceData() is invoked automatically.
Passing Device data to -DeviceData can save significant processing time.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OutputFolder
{{ Fill OutputFolder Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: "$($env:USERPROFILE)\Documents"
Accept pipeline input: False
Accept wildcard characters: False
```

### -Title
Title used for prefix of XLSX filename

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UserName
UserPrincipalName for authentication

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Overwrite
Replace output file it exists

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Distinct
Filter DeviceName+AppName only to remove duplicates arising from different versions

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -DaysOld
Filter stale accounts by specified number of days (range 10 to 1000, default = 180)

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: 180
Accept pipeline input: False
Accept wildcard characters: False
```

### -DeviceOS
Filter devices and derivative datasets to specified OS. 
Options include: Windows, iOS, Android, or All.
Default is 'All'

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: All
Accept pipeline input: False
Accept wildcard characters: False
```

### -Show
Open workbook in Excel when completed (requires Excel on host machine)

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
NAME: Export-psIntuneInventory
Requires PS module ImportExcel

## RELATED LINKS

[https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Export-psIntuneInventory.md](https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Export-psIntuneInventory.md)


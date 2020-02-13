---
external help file: psIntune-help.xml
Module Name: psIntune
online version: https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-psIntuneDevices.md
schema: 2.0.0
---

# Get-psIntuneDevices

## SYNOPSIS
Returns dataset of Intune-managed devices with inventoried apps

## SYNTAX

```
Get-psIntuneDevices [-UserName] <String> [-ShowProgress] [-Detailed] [-NoApps] [<CommonParameters>]
```

## DESCRIPTION
Returns dataset of Intune-managed devices with inventoried apps

## EXAMPLES

### EXAMPLE 1
```
$devices = Get-psIntuneDevices -UserName "john.doe@contoso.com"
```

Returns results of online request to variable $devices

### EXAMPLE 2
```
$devices = Get-psIntuneDevices -UserName "john.doe@contoso.com" -ShowProgress
```

Returns results of online request to variable $devices while displaying concurrent progress

### EXAMPLE 3
```
$devices = Get-psIntuneDevices -UserName "john.doe@contoso.com" -Detailed -NoApps
```

Returns detailed results of online request to variable $devices without installed applications data

### EXAMPLE 4
```
$devices = Get-psIntuneDevices -UserName "john.doe@contoso.com" -NoApps
```

Returns summary results of online request to variable $devices without installed applications data
This is the fastest query option of all the parameter options

## PARAMETERS

### -UserName
UserPrincipalName for authentication request

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ShowProgress
Display progress as data is exported (default is silent / no progress shown)

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

### -Detailed
Optional expanded list of device properties which includes:
* DeviceName, DeviceID, Manufacturer, Model, MemoryGB, DiskSizeGB, FreeSpaceGB,	EthernetMAC, 
  SerialNumber, OSName, OSVersion, Ownership, Category, LastSyncTime, UserName, Apps
* The default return property set: DeviceName, DeviceID, OSName, OSVersion, LastSyncTime, UserName, Apps
* Note that for either case, Apps will be set to $null if parameter -NoApps is used

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

### -NoApps
Exclude installed Applications data from return dataset
This reduces overall query time significantly!

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
NAME: Get-psIntuneDevices

## RELATED LINKS

[https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-psIntuneDevices.md](https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-psIntuneDevices.md)


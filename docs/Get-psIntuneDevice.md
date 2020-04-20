---
external help file: psIntune-help.xml
Module Name: psintune
online version: https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-psIntuneDevice.md
schema: 2.0.0
---

# Get-psIntuneDevice

## SYNOPSIS
Returns dataset of Intune-managed devices with inventoried apps

## SYNTAX

```
Get-psIntuneDevice [-UserName] <String> [[-DeviceName] <String>] [[-Detail] <String>] [[-DeviceOS] <String>]
 [-ShowProgress] [[-graphApiVersion] <String>] [<CommonParameters>]
```

## DESCRIPTION
Returns dataset of Intune-managed devices with inventoried apps

## EXAMPLES

### EXAMPLE 1
```
$devices = Get-psIntuneDevice -UserName "john.doe@contoso.com" -DeviceName "Desktop123" -Detail Detailed
```

Returns detailed data for one device without installed applications

### EXAMPLE 2
```
$devices = Get-psIntuneDevice -UserName "john.doe@contoso.com" -DeviceOS Windows -Detail Detailed
```

Returns detailed data for Windows devices without applications

### EXAMPLE 3
```
$devices = Get-psIntuneDevice -UserName "john.doe@contoso.com"
```

Returns summary data without applications

### EXAMPLE 4
```
$devices = Get-psIntuneDevice -UserName "john.doe@contoso.com" -ShowProgress
```

Returns summary data without applications and shows progress during processing

### EXAMPLE 5
```
$devices = Get-psIntuneDevice -UserName "john.doe@contoso.com" -Detail -Full -ShowProgress
```

Returns detailed data with applications for each device and shows progress during processing

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

### -DeviceName
Filter query to just one specified device by name.
Default is query all devices

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Detail
Controls the level of granularity of the results:
* Summary - returns basic device information only
* Detailed - returns detailed device information
* Full - returns detailed device information with installed applications
* Raw - returns raw Graph API results only

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: Summary
Accept pipeline input: False
Accept wildcard characters: False
```

### -DeviceOS
Filter devices by operating system.
Options: Android, iOS, Windows, All
Default is All

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: All
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

### -graphApiVersion
Graph API version.
Default is "beta"

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: Beta
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Collections.Hashtable
## NOTES
NAME: Get-psIntuneDevice

## RELATED LINKS

[https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-psIntuneDevice.md](https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-psIntuneDevice.md)


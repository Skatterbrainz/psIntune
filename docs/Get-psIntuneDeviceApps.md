---
external help file: psIntune-help.xml
Module Name: psIntune
online version: https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-psIntuneDeviceApps.md
schema: 2.0.0
---

# Get-psIntuneDeviceApps

## SYNOPSIS
Queries Installed Apps on Intune devices

## SYNTAX

```
Get-psIntuneDeviceApps [-Devices] <Object> [[-UserName] <String>] [[-ShowProgress] <Boolean>]
 [[-Expand] <Boolean>] [[-graphApiVersion] <String>] [<CommonParameters>]
```

## DESCRIPTION
Queries Installed Apps on Intune managed devices

## EXAMPLES

### EXAMPLE 1
```
$devices = Get-psIntuneDevice -UserName $userid -Detail Detailed -ShowProgress
```

$apps = Get-psIntuneDeviceApps -Devices $devices -UserName $userid -ShowProgress

Gathers all Intune managed devices without their installed apps, then passes
the $devices array to query the installed applications per device.

## PARAMETERS

### -Devices
Data returned from Get-psIntuneDevice

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UserName
UserPrincipalName for authentication request

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: $($global:psintuneuser)
Accept pipeline input: False
Accept wildcard characters: False
```

### -ShowProgress
Display progress as data is exported (default is silent / no progress shown)

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Expand
Returns app information only.
Default returns an object with Apps as a nested property

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
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

## NOTES
NAME: Get-psIntuneDeviceApps

## RELATED LINKS

[https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-psIntuneDeviceApps.md](https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-psIntuneDeviceApps.md)


---
external help file: psIntune-help.xml
Module Name: psIntune
online version: https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-ManagedDevices.md
schema: 2.0.0
---

# Get-ManagedDevices

## SYNOPSIS
This function is used to get Intune Managed Devices from the Graph API REST interface

## SYNTAX

```
Get-ManagedDevices [-UserName] <String> [[-DeviceName] <String>] [-IncludeEAS] [-ExcludeMDM]
 [<CommonParameters>]
```

## DESCRIPTION
The function connects to the Graph API Interface and gets any Intune Managed Device

## EXAMPLES

### EXAMPLE 1
```
Get-ManagedDevices
```

Returns all managed devices but excludes EAS devices registered within the Intune Service

### EXAMPLE 2
```
Get-ManagedDevices -IncludeEAS
```

Returns all managed devices including EAS devices registered within the Intune Service

## PARAMETERS

### -UserName
{{ Fill UserName Description }}

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
{{ Fill DeviceName Description }}

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

### -IncludeEAS
Switch to include EAS devices (not included by default)

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

### -ExcludeMDM
Switch to exclude MDM devices (not excluded by default)

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
NAME: Get-ManagedDevices

## RELATED LINKS

[https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-ManagedDevices.md](https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-ManagedDevices.md)


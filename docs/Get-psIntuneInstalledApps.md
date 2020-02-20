---
external help file: psIntune-help.xml
Module Name: psIntune
online version: https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-psIntuneInstalledApps.md
schema: 2.0.0
---

# Get-psIntuneInstalledApps

## SYNOPSIS
Returns App inventory data from Intune Device data set

## SYNTAX

```
Get-psIntuneInstalledApps [-DataSet] <Object> [-GroupByName] [<CommonParameters>]
```

## DESCRIPTION
Returns App inventory data from Intune Device data set

## EXAMPLES

### EXAMPLE 1
```
$devices = Get-psIntuneDevice -UserName "john.doe@contoso.com"
```

$applist = Get-psIntuneInstalledApps -DataSet $devices

## PARAMETERS

### -DataSet
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

### -GroupByName
{{ Fill GroupByName Description }}

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
NAME: Get-psIntuneInstalledApps

## RELATED LINKS

[https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-psIntuneInstalledApps.md](https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-psIntuneInstalledApps.md)


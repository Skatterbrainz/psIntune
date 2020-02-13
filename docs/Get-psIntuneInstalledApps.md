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
Get-psIntuneInstalledApps [[-DataSet] <Object>]
```

## DESCRIPTION
Returns App inventory data from Intune Device data set

## EXAMPLES

### EXAMPLE 1
```
$devices = Get-psIntuneDevices -UserName "john.doe@contoso.com"
```

$applist = Get-DsIntuneDeviceApps -DataSet $devices

## PARAMETERS

### -DataSet
Data returned from Get-psIntuneDevices()

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

## INPUTS

## OUTPUTS

## NOTES
NAME: Get-psIntuneInstalledApps

## RELATED LINKS

[https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-psIntuneInstalledApps.md](https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-psIntuneInstalledApps.md)


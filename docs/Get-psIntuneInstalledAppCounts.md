---
external help file: psIntune-help.xml
Module Name: psIntune
online version: https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-psIntuneInstalledAppCounts.md
schema: 2.0.0
---

# Get-psIntuneInstalledAppCounts

## SYNOPSIS
Return Applications grouped and sorted by Installation Counts

## SYNTAX

```
Get-psIntuneInstalledAppCounts [[-AppDataSet] <Object>] [[-RowCount] <Int32>] [<CommonParameters>]
```

## DESCRIPTION
Return Applications grouped and sorted by Installation Counts in descending order

## EXAMPLES

### EXAMPLE 1
```
$apps = Get-psIntuneInstalledApps -DataSet $devices
```

$top20 = Get-psIntuneInstalledAppCounts -AppDataSet $apps -RowCount 20

## PARAMETERS

### -AppDataSet
Applications dataset returned from Get-psIntuneInstalledApps()

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

### -RowCount
Limit to first (N) rows (default is 0 / returns all rows)

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
NAME: Get-psIntuneInstalledAppCounts

## RELATED LINKS

[https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-psIntuneInstalledAppCounts.md](https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-psIntuneInstalledAppCounts.md)


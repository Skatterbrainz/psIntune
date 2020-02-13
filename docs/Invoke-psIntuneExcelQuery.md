---
external help file: psIntune-help.xml
Module Name: psIntune
online version: https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Invoke-psIntuneExcelQuery.md
schema: 2.0.0
---

# Invoke-psIntuneExcelQuery

## SYNOPSIS
Query Excel Workbook/WorkSheet using SQL statement

## SYNTAX

```
Invoke-psIntuneExcelQuery [-FilePath] <String> [-Query] <String> [<CommonParameters>]
```

## DESCRIPTION
Same as above

## EXAMPLES

### EXAMPLE 1
```
$xlFile = "c:\myfiles\IntuneDeviceData.xlsx"
```

$query = "select DeviceName,ProductName from \[IntuneApps$\] where ProductName='Crapware 2019'"
$rows = Invoke-psIntuneExcelQuery -FilePath $xlFile -Query $query

## PARAMETERS

### -FilePath
Path and filename to .xlsx workbook file

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

### -Query
SQL query statement

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
NAME: Invoke-psIntuneExcelQuery

## RELATED LINKS

[https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Invoke-psIntuneExcelQuery.md](https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Invoke-psIntuneExcelQuery.md)


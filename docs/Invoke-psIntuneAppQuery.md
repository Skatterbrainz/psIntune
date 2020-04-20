---
external help file: psIntune-help.xml
Module Name: psintune
online version: https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Invoke-psIntuneAppQuery.md
schema: 2.0.0
---

# Invoke-psIntuneAppQuery

## SYNOPSIS
Query DataSet for unique App installation counts

## SYNTAX

```
Invoke-psIntuneAppQuery [-AppDataSet] <Object> [-ProductName] <String> [<CommonParameters>]
```

## DESCRIPTION
Filters instances of application installations by Name/Title only to determine
unique installations by device. 
Some devices will report multiple instances of 
the same application, with different ProductVersion numbers.
This function excludes
duplicates to show one-per-device only.

## EXAMPLES

### EXAMPLE 1
```
$devices = Get-DsIntuneDeviceData -UserName "john.doe@contoso.com"
```

$applist = Get-DsIntuneDeviceApps -DataSet $devices
$rows = Invoke-psIntuneAppQuery -AppDataSet $applist -ProductName "Acme Crapware 19.20 64-bit"

## PARAMETERS

### -AppDataSet
Device data returned from Get-DsIntuneDeviceData().
If not provided, Get-DsIntuneDeviceData() is invoked automatically.
Passing Device data to -DeviceData can save significant processing time.

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

### -ProductName
Application Product name

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
NAME: Invoke-psIntuneAppQuery

## RELATED LINKS

[https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Invoke-psIntuneAppQuery.md](https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Invoke-psIntuneAppQuery.md)


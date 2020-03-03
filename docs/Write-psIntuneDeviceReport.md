---
external help file: psIntune-help.xml
Module Name: psIntune
online version: https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Invoke-psIntuneAppQuery.md
schema: 2.0.0
---

# Write-psIntuneDeviceReport

## SYNOPSIS
Export Inventory Data to Excel Workbook

## SYNTAX

```
Write-psIntuneDeviceReport [[-Devices] <Object>] [[-Apps] <Object>] [[-OutputFolder] <String>]
 [[-Title] <String>] [[-DeviceOS] <String>] [[-StaleLimit] <Int32>] [[-LowDiskGB] <Int32>] [-AzureAD]
 [-Overwrite] [-Show] [-NoDateStamp] [<CommonParameters>]
```

## DESCRIPTION
Export Intune Device inventory data to Excel Workbook

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -Devices
{{ Fill Devices Description }}

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

### -Apps
{{ Fill Apps Description }}

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OutputFolder
Path for output file.
Default is current user Documents path

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: "$($env:USERPROFILE)\Documents"
Accept pipeline input: False
Accept wildcard characters: False
```

### -Title
Title to use for output filename

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

### -DeviceOS
Filter devices by operating system.
Options: Android, iOS, Windows, All
Default is All

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: All
Accept pipeline input: False
Accept wildcard characters: False
```

### -StaleLimit
Number of days since last Intune synchronization to consider as a stale account
Default is 180

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: 180
Accept pipeline input: False
Accept wildcard characters: False
```

### -LowDiskGB
Free disk space GB to indicate "low disk space".
Default is 20

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: 20
Accept pipeline input: False
Accept wildcard characters: False
```

### -AzureAD
Includes AzureAD device accounts with report

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

### -Overwrite
If output file exists, with same name, it will be overwritten.
Default is to abort if idential filename exists.

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

### -Show
Display workbook when export is complete.
Default is to not show

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

### -NoDateStamp
Do not include datestamp in the output filename (default is "_YYYY-MM-DD" suffix)

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

## RELATED LINKS

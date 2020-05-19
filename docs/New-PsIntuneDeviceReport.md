---
external help file: psIntune-help.xml
Module Name: psIntune
online version: https://github.com/Skatterbrainz/psIntune/blob/master/docs/New-PsIntuneDeviceReport.md
schema: 2.0.0
---

# New-PsIntuneDeviceReport

## SYNOPSIS
Quick Report version of Write-PsIntuneDeviceReport

## SYNTAX

```
New-PsIntuneDeviceReport [-UserName] <String> [-ReportName] <String> [[-DeviceOS] <String>]
 [[-OutputFolder] <String>] [-Show] [<CommonParameters>]
```

## DESCRIPTION
Yeah.
What he said

## EXAMPLES

### EXAMPLE 1
```
New-PsIntuneDeviceReport -UserName "john@contoso.com" -ReportName "Contoso" -DeviceOS 'Windows'
```

## PARAMETERS

### -UserName
User account to use for AzureAD and Intune tenant

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

### -ReportName
Title to include in the report filename

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

### -DeviceOS
Filter devices by operating system.
Options: Android, iOS, Windows, All.
Default is All

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: All
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
Position: 4
Default value: "$([System.Environment]::GetFolderPath('Personal'))"
Accept pipeline input: False
Accept wildcard characters: False
```

### -Show
Open results in Excel (if Excel is installed on the machine where script is executed)

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

[https://github.com/Skatterbrainz/psIntune/blob/master/docs/New-PsIntuneDeviceReport.md](https://github.com/Skatterbrainz/psIntune/blob/master/docs/New-PsIntuneDeviceReport.md)


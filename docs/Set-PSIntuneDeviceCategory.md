---
external help file: psIntune-help.xml
Module Name: psIntune
online version: https://github.com/Skatterbrainz/psIntune/blob/master/docs/New-PsIntuneDeviceReport.md
schema: 2.0.0
---

# Set-PSIntuneDeviceCategory

## SYNOPSIS
Batch update Intune device category assignment

## SYNTAX

```
Set-PSIntuneDeviceCategory [-InputFile] <String> [-CategoryName] <String> [-Credential] <PSCredential>
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Batch update Intune device category assignment using
an input file (csv or txt) to filter the computer names

## EXAMPLES

### EXAMPLE 1
```
Set-PSIntuneDeviceCategory -InputFile ".\computers.txt" -CategoryName "Personal" -Credential $mycredential
```

### EXAMPLE 2
```
Set-PSIntuneDeviceCategory -InputFile ".\computers.csv" -CategoryName "Corporate" -Credential $mycredential
```

## PARAMETERS

### -InputFile
{{ Fill InputFile Description }}

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

### -CategoryName
A valid category name. 
If the name does not exist in the
Intune subscription, it will return an error

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

### -Credential
User with permissions to access and modify Intune managed devices

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
Requires an Azure AD app registration with Application permissions assigned:
Device.Read / Read.All / ReadWrite.All
DeviceManagementManagedDevice.Read.All / ReadWrite.All
0.1 - 2021-02-03 - David Stein, Catapult Systems

## RELATED LINKS

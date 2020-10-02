---
external help file: psIntune-help.xml
Module Name: psIntune
online version: https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-psIntuneInstalledApps.md
schema: 2.0.0
---

# Import-PsIntuneCredential

## SYNOPSIS
Import PS Credential object from XML file

## SYNTAX

```
Import-PsIntuneCredential [[-Path] <String>] [[-Folder] <String>] [<CommonParameters>]
```

## DESCRIPTION
Import PS Credential object from XML file

## EXAMPLES

### EXAMPLE 1
```
$mycred = Import-PsIntuneCredential -Path ".\cred_contoso_azure.xml"
```

### EXAMPLE 2
```
$mycred = Import-PsIntuneCredential
```

### EXAMPLE 3
```
$mycred = Import-PsIntuneCredential -Folder "c:\credentials"
```

## PARAMETERS

### -Path
Optional file path to XML file.
If not provided, a GUI file selection form is provided

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Folder
Optional default search path when Path is not provide and GUI form is displayed for file selection

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

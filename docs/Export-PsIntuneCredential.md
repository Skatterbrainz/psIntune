---
external help file: psIntune-help.xml
Module Name: psIntune
online version:
schema: 2.0.0
---

# Export-PsIntuneCredential

## SYNOPSIS
Save PS Credential object to encoded XML file

## SYNTAX

```
Export-PsIntuneCredential [-OutputFile] <String> [[-Credential] <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION
Save PS Credential object to encoded XML file

## EXAMPLES

### EXAMPLE 1
```
Export-PsIntuneCredential -OutputPath ".\cred_contoso_azure.xml"
```

### EXAMPLE 2
```
Export-PsIntuneCredential -OutputPath ".\cred_contoso_azure.xml" -Credential $mycred
```

## PARAMETERS

### -OutputFile
Path to XML file

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

### -Credential
Optional PS crecential object.
If not provided, GUI prompt is provided

```yaml
Type: PSCredential
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

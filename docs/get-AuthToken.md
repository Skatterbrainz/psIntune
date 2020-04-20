---
external help file: psIntune-help.xml
Module Name: psintune
online version:
schema: 2.0.0
---

# get-AuthToken

## SYNOPSIS
This function is used to authenticate with the Graph API REST interface

## SYNTAX

```
get-AuthToken [-User] <Object> [<CommonParameters>]
```

## DESCRIPTION
The function authenticate with the Graph API Interface with the tenant name

## EXAMPLES

### EXAMPLE 1
```
Get-AuthToken -User "john.doe@contoso.com"
```

Authenticates user with the Graph API interface

## PARAMETERS

### -User
UserName for cloud services access

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
NAME: Get-AuthToken

## RELATED LINKS

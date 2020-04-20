---
external help file: psIntune-help.xml
Module Name: psintune
online version: https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-psIntuneAzureADUser.md
schema: 2.0.0
---

# Get-psIntuneAzureADUser

## SYNOPSIS
This function is used to get AAD Users from the Graph API REST interface

## SYNTAX

```
Get-psIntuneAzureADUser [[-userPrincipalName] <String>] [[-Property] <String>] [<CommonParameters>]
```

## DESCRIPTION
The function connects to the Graph API Interface and gets any users registered with AAD

## EXAMPLES

### EXAMPLE 1
```
Get-psIntuneAzureADUser
```

Returns all users registered with Azure AD

### EXAMPLE 2
```
Get-psIntuneAzureADUser -userPrincipleName user@domain.com
```

Returns specific user by UserPrincipalName registered with Azure AD

## PARAMETERS

### -userPrincipalName
{{ Fill userPrincipalName Description }}

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

### -Property
{{ Fill Property Description }}

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
NAME: Get-psIntuneAzureADUser

## RELATED LINKS

[https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-psIntuneAzureADUser.md](https://github.com/Skatterbrainz/ds-intune/blob/master/docs/Get-psIntuneAzureADUser.md)


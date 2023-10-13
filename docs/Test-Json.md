---
external help file: ValidateJson-help.xml
Module Name: ValidateJson
online version: https://github.com/mdlopresti/ValidateJson/blob/main/docs/Test-Json.md
schema: 2.0.0
---

# Test-Json

## SYNOPSIS
Tests whether a string is a valid JSON document

## SYNTAX

### Json (Default)
```
Test-Json [-Json] <String> [<CommonParameters>]
```

### File
```
Test-Json [-Json] <String> -SchemaFile <String> [<CommonParameters>]
```

### Schema
```
Test-Json [-Json] <String> [-Schema] <String> [<CommonParameters>]
```

## DESCRIPTION
The Test-Json cmdlet tests whether a string is a valid JavaScript Object Notation (JSON) document and can optionally verify that JSON document against a provided schema.

The verified string can then be used with the ConvertFrom-Json cmdlet convert a JSON-formatted string to a JSON object, which is easily managed in PowerShell or sent to another program or web service that access JSON input.

## EXAMPLES

### EXAMPLE 1
```
"{'name': 'Ashley', 'age': 25}" | Test-Json
```

True

## PARAMETERS

### -Json
Specifies the JSON string to test for validity.
Enter a variable that contains the string, or type a command or expression that gets the string.

```yaml
Type: String
Parameter Sets: Json, Schema
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: File
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Schema
Specifies a schema to validate the JSON input against.
If passed, Test-Json validates that the JSON input conforms to the spec specified by the Schema parameter and return $true only if the input conforms to the provided schema.

```yaml
Type: String
Parameter Sets: Schema
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SchemaFile
Specifies a schema file used to validate the JSON input.
When used, the Test-Json returns $true only if the JSON input conforms to the schema defined in the file specified by the SchemaFile parameter.

```yaml
Type: String
Parameter Sets: File
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Boolean
## NOTES

## RELATED LINKS

[https://github.com/mdlopresti/ValidateJson/blob/main/docs/Test-Json.md](https://github.com/mdlopresti/ValidateJson/blob/main/docs/Test-Json.md)


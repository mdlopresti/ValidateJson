#Requires -Version 5.1

function finddll {
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
    param (
        $packagename,
        $version
    )
    $files = Get-ChildItem "$PSScriptRoot\lib\" | `
        Where-Object {$_.Name -like "$packagename*"} | `
        Get-ChildItem -Recurse -Include "*.dll" | `
        Select-Object -ExpandProperty FullName | `
        Where-Object {$_ -like "*net45\$packagename.dll"}

    if($version){
        $files = $files | Where-Object {$_ -like "*$version*"}
    }
    return $files
}


function pullPackageList(){
    $results = @()
    (Import-PowerShellDataFile "$PSScriptRoot\PackageRequirements.psd1")['Packages'] | foreach-object {
        $results += finddll $_['package'] $_['version']
    }
    return $results
}


foreach ($dll in pullPackageList) {
    try   {
        Add-Type -LiteralPath $dll
    }
    catch {
        Write-Error $_.Exception.LoaderExceptions
    }
}


function validate {
    [CmdletBinding()]
    [OutputType([Boolean])]
    param (
        $JsonString,
        $SchemaString
    )
    $schemaObject = [NJsonSchema.JsonSchema]::FromJsonAsync(
        [string]$SchemaString #type flag is required to make this work
    ).GetAwaiter().GetResult()
    try {
        $result = $schemaObject.Validate($JsonString)
        if($result.count -eq 0) {
            return $true
        } else {
            return $result
        }
    } catch {
        if($_.FullyQualifiedErrorId -eq "JsonReaderException") {
            return $false
        } else {
            throw $_
        }
    }
}


function Test-Json {
    <#
    .SYNOPSIS
        Tests whether a string is a valid JSON document
    .DESCRIPTION
        The Test-Json cmdlet tests whether a string is a valid JavaScript Object Notation (JSON) document and can optionally verify that JSON document against a provided schema.

        The verified string can then be used with the ConvertFrom-Json cmdlet convert a JSON-formatted string to a JSON object, which is easily managed in PowerShell or sent to another program or web service that access JSON input.
    .PARAMETER Json
        Specifies the JSON string to test for validity. Enter a variable that contains the string, or type a command or expression that gets the string.
    .PARAMETER Schema
        Specifies a schema to validate the JSON input against. If passed, Test-Json validates that the JSON input conforms to the spec specified by the Schema parameter and return $true only if the input conforms to the provided schema.
    .PARAMETER SchemaFile
        Specifies a schema file used to validate the JSON input. When used, the Test-Json returns $true only if the JSON input conforms to the schema defined in the file specified by the SchemaFile parameter.
    .EXAMPLE
        PS> "{'name': 'Ashley', 'age': 25}" | Test-Json
        Returns Boolean
    .LINK
        https://github.com/mdlopresti/ValidateJson/blob/main/docs/Test-Json.md
    #>
    [CmdletBinding(DefaultParameterSetName = 'Json')]
    [OutputType([Boolean])]
    param (
        [Parameter(Mandatory, ParameterSetName = 'Json', Position = 0,ValueFromPipeline)]
        [Parameter(Mandatory, ParameterSetName = 'Schema', Position = 0,ValueFromPipeline)]
        [Parameter(Mandatory, ParameterSetName = 'File', Position = 0,ValueFromPipeline)]
        [String]
        $Json,

        [Parameter(Mandatory, ParameterSetName = 'Schema', Position = 1)]
        [String]
        $Schema,

        [Parameter(Mandatory, ParameterSetName = 'File')]
        [String]
        $SchemaFile
    )
process {
    switch ($PSCmdlet.ParameterSetName) {
        "Json" {
            try {
                ConvertFrom-Json -InputObject $Json | Out-Null
                return $true
            }
            catch {
                return $false
            }

        }
        "Schema" {
            return validate -JsonString $Json -SchemaString $Schema
        }
        "File" {
            return validate -JsonString $Json -SchemaString $(Get-Content -Path $SchemaFile)
        }
    }
}
}
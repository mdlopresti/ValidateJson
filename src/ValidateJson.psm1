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
    param (
        $Json,
        $Schema
    )
    return [NJsonSchema.Validation.JsonSchemaValidator]::new().Validate($json,$Schema)
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
    #>
    [CmdletBinding(DefaultParameterSetName = 'Json')]
    [OutputType([Boolean])]
    param (
        [Parameter(Mandatory, ParameterSetName = 'Json', Position = 0)]
        [Parameter(Mandatory, ParameterSetName = 'Schema', Position = 0)]
        [Parameter(Mandatory, ParameterSetName = 'File')]
        [String]
        $Json,

        [Parameter(Mandatory, ParameterSetName = 'Schema', Position = 1)]
        [String]
        $Schema,

        [Parameter(Mandatory, ParameterSetName = 'File')]
        [String]
        $SchemaFile
    )

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
            return validate($json,$Schema)
        }
        "File" {
            return validate($json,$(Get-Content -Path $SchemaFile))
        }
    }
}
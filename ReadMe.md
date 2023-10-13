# ValidateJson

Json validation for older PowerShell.

## Description

Test-Json is not implemented for Powershell 5.1, however there are many Powershell modules out there that do not support Powershell 6.0+, this module fills that gap.  The version of the function in this module is a direct drop-in replacement for the official [Test-Json](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/test-json), accepting the exact same parameters.

The project relies on the  [NJsonSchema](https://github.com/RicoSuter/NJsonSchema) nugget package.  

## Todo

- ~~Functional MVP~~
- ~~Invoke-Build build and package process~~
- ~~Manual Publish to PSGallery~~
- ~~GitHub Actions CI~~
- ~~CI required on PRs~~
- GitHub Actions CD w/psgallery publish ~~and GitHub Artifacts~~
- STARTED Pester Unit Testing
- ~~Help docs with [platyPS](https://github.com/PowerShell/platyPS)~~

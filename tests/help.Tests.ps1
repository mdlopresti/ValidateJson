$commands = (Import-PowerShellDataFile "$PSScriptRoot\..\src\ValidateJson.psd1")["FunctionsToExport"]
Write-host "$PSScriptRoot\..\src\ValidateJson.psd1"
        
Describe "Checking Help file on <_>" -ForEach $commands {
    BeforeAll {
        $command = $_
        Import-Module "$PSScriptRoot\..\src\ValidateJson.psd1"
        $help = Get-Help -Name $command -Category "Function"
    }
    It "Should have help" {
        $help | Should -Not -BeNullOrEmpty
    }
    It "Should have synopsis" {
        $help.Synopsis | Should -Not -BeNullOrEmpty
    }
    It "Should have a description" {
        $help.description.Text | Should -Not -BeNullOrEmpty
    }
    It "Should have examples" {
        $help.examples | Should -Not -BeNullOrEmpty
    }
    It "All Parameters Should have a description" {
        $help.parameters.parameter | foreach-object {
            $_.description.Text | Should -Not -BeNullOrEmpty
        }
    }
}
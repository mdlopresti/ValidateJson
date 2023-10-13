$commands = (Import-PowerShellDataFile "$PSScriptRoot\..\src\ValidateJson.psd1")["FunctionsToExport"]
Import-Module "$PSScriptRoot\..\src\ValidateJson.psd1" -Force
Write-host "$PSScriptRoot\..\src\ValidateJson.psd1"
        
Foreach ($command in $commands) {
    Describe "Checking Help file on $command" {
        BeforeAll {
            Write-host $command
            $help = Get-Help -Name $command -Category "Function"
            Write-host ($help).Name
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
} 
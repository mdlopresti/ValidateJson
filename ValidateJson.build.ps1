param(
    # Custom build root, still the original $BuildRoot by default.
    $BuildRoot = $BuildRoot,
    $module_name = "ValidateJson",
    $zipPackage = $false
)
$module_name = "ValidateJson"
$nuspecPath = "$BuildRoot\src\$module_name.nuspec"

Enter-BuildTask {
    Set-location $BuildRoot
}

# Synopsis: Remove temp files.
task clean {
	remove "src\lib\**", "src\$module_name.nuspec", "src\$module_name.psd1", "*.zip", "dist"
}



# Fetch values
task fetch_version {
    $template=[xml](Get-Content "$BuildRoot\tools\nuspec.template")
    $script:Version = $template.package.metadata.version
    Write-Build Green "Version is $script:Version"
}
task fetch_required_packages {
    $script:RequiredPackages = (Import-PowerShellDataFile "$BuildRoot\src\PackageRequirements.psd1")['Packages']
}
task fetch_dll_paths install_packages, {
    $script:dllPaths = Get-ChildItem "$BuildRoot\src\" -Recurse -include "*net45*" | `
        Select-Object -ExpandProperty Fullname | `
        Where-Object {$_ -notlike "*portable*"}
}
task fetch fetch_version, fetch_required_packages, fetch_dll_paths

# build out codebase
task install_packages fetch_required_packages, {
    $script:RequiredPackages | foreach-object {
        if(-not (Test-Path "$BuildRoot\src\lib\$($_['package']).$($_['version'])")) {
            nuget install  $_['package'] -OutputDirectory "$BuildRoot\src\lib\" -Version $_['version'] | out-null
            Write-Build Green "Installing $($_['package']).$($_['version'])"
        } else {
            Write-Build Green "$($_['package']).$($_['version']) is already installed, skipping."
        }
        
    }
}
task generate_nuspec fetch_required_packages, {
    if(Test-Path $nuspecPath){
        $manifest = [xml](Get-Content $nuspecPath)
        Write-Build Green "Updating existing nuspec file"
    } else {
        $manifest = [xml](Get-Content "$BuildRoot\tools\nuspec.template")
        Write-Build Yellow "Creating new nuspec file from template"
    }
    $manifest.package.metadata.id = $module_name
    $manifest.package.metadata.copyright = "Copyright $($(Get-Date).Year)"
    $manifest.package.metadata.projectUrl = "https://github.com/mdlopresti/$module_name"
    $manifest.package.metadata.readme = "docs\ReadMe.md"

    $manifest.Save($nuspecPath)
}
task generate_manifest generate_nuspec, fetch_dll_paths, {
    Set-location "$BuildRoot\src"
    $manifest = [xml](Get-Content $nuspecPath)
    if((git branch --show-current) -ne "main") {
        $extraParams = @{
            privateData = @{
                Prerelease = "dev"
            }
        }
    } else {
        $extraParams = @{}
    }
    New-ModuleManifest -Path ".\$module_name.psd1" `
        -Description $manifest.package.metadata.description `
        -Author "mdlopresti" `
        -FunctionsToExport "Test-Json" `
        -CmdletsToExport "" `
        -AliasesToExport "" `
        -Copyright $manifest.package.metadata.copyright `
        -Guid "b8e80ca6-a7fb-4bf3-b9fd-b0f8d99488a2" `
        -ModuleVersion $manifest.package.metadata.version `
        -RootModule "$module_name.psm1" `
        -PowerShellVersion "5.1" `
        -Tags $manifest.package.metadata.tags `
        -LicenseUri ($manifest.package.metadata.projectUrl + "/blob/main/LICENSE.md") `
        -ProjectUri $manifest.package.metadata.projectUrl `
        -FileList (
            $script:dllPaths | `
            foreach-object { 
                Get-ChildItem -Path $_ -Recurse -include "*.dll" | `
                Select-Object -ExpandProperty Fullname
            }
        ) `
        @extraParams
    

    if((git branch --show-current) -like "feature/*") {
        $privateData = (Import-PowerShellDataFile "$module_name.psd1")['PrivateData']
        $privateData["PSData"]["Prerelease"] = "dev"
        Update-ModuleManifest -Path "$module_name.psd1" -PrivateData $privateData
    }
}
task rebuild clean, generate_manifest, install_packages

# test/validate
task analyze {
    $output = Invoke-ScriptAnalyzer "$BuildRoot\src\$module_name.psm1"
    if($output){
        $output
        throw "Script Analysis Failed"
    }
    Write-Build green "Script Analysis found no errors"
}
task test {
    Invoke-Pester
}
task validate generate_nuspec, generate_manifest, install_packages, analyze, test

# generate package
task generate_package generate_manifest, {
    New-Item -Path $BuildRoot -Name "dist" -ItemType "directory" -Force | out-null
    New-Item -Path "$BuildRoot\dist" -Name $module_name -ItemType "directory" -Force | out-null
    Copy-Item -Path "$BuildRoot\src\*.psm1","$BuildRoot\src\*.psd1" -Destination "$BuildRoot\dist\$module_name\"
    $script:dllPaths | foreach-object {
        $fullpath = $_
        $relativePath = $fullpath.replace("$BuildRoot\src",".")
        $targetPath = "$BuildRoot\dist\$module_name\$relativePath"
        New-Item -Path (Split-Path -Parent $targetPath) -Name (Split-Path -leaf $targetPath ) -ItemType "directory" -Force | out-null
        Get-ChildItem -Path $fullpath -Recurse -include "*.dll" | `
            foreach-object {Copy-Item -Path $_ -Destination $targetPath -Recurse -Force}
    }
    if($zipPackage) {
        Compress-Archive -Path "$BuildRoot\dist\$module_name\*" -DestinationPath "$BuildRoot\dist\$module_name.zip"
    }
}
task package rebuild, generate_package, analyze

# publish package
task publish install_packages, generate_package, {
    Publish-Module -Path "$BuildRoot\dist\$module_name" -NuGetApiKey $env:NuGetApiKey -Force
}

# default tasks
task . generate_package, validate

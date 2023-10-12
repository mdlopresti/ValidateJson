param(
    # Custom build root, still the original $BuildRoot by default.
    $BuildRoot = $BuildRoot,
    $module_name = "ValidateJson"
)
$module_name = "ValidateJson"
$nuspecPath = "$BuildRoot/$module_name/$module_name.nuspec"

# Synopsis: Remove temp files.
task clean {
	remove "$module_name/lib/**", "$module_name/$module_name.nuspec", "$module_name/$module_name.psd1", "*.zip", "dist"
}
task version {
    $template=[xml](Get-Content "$BuildRoot/tools/nuspec.template")
    $script:Version = $template.package.metadata.version
    Write-Build Green "Version is $script:Version"
}
task fetch_required_packages {
    $script:RequiredPackages = (Import-PowerShellDataFile "$BuildRoot/$module_name/PackageRequirements.psd1")['Packages']
}

# install nuget packages
task install_packages fetch_required_packages, {
    $script:RequiredPackages | foreach-object {
        if(-not (Test-Path "$BuildRoot/$module_name/lib/$($_['package']).$($_['version'])")) {
            nuget install  $_['package'] -OutputDirectory "$BuildRoot/$module_name/lib/" -Version $_['version'] | out-null
            Write-Build Green "Installing $($_['package']).$($_['version'])"
        } else {
            Write-Build Green "$($_['package']).$($_['version']) is already installed, skipping."
        }
        
    }
}

# generate the nuspec file
task generate_nuspec fetch_required_packages, {
    if(Test-Path $nuspecPath){
        $manifest = [xml](Get-Content $nuspecPath)
        Write-Build Green "Updating existing nuspec file"
    } else {
        $manifest = [xml](Get-Content "$BuildRoot/tools/nuspec.template")
        Write-Build Yellow "Creating new nuspec file from template"
    }
    $manifest.package.metadata.id = $module_name
    $manifest.package.metadata.copyright = "Copyright $($(Get-Date).Year)"
    $manifest.package.metadata.projectUrl = "https://github.com/mdlopresti/$module_name"
    $manifest.package.metadata.readme = "docs\ReadMe.md"

    $manifest.Save($nuspecPath)
}

# generate the manifest
task generate_manifest generate_nuspec, {
    $manifest = [xml](Get-Content $nuspecPath)
    New-ModuleManifest -Path "$BuildRoot/$module_name/$module_name.psd1" `
        -Author "mdlopresti" `
        -FunctionsToExport "Test-Json" `
        -CmdletsToExport "" `
        -AliasesToExport "" `
        -Copyright $manifest.package.metadata.copyright `
        -Guid "b8e80ca6-a7fb-4bf3-b9fd-b0f8d99488a2" `
        -ModuleVersion $manifest.package.metadata.version `
        -RootModule "$BuildRoot/$module_name/$module_name.psm1" `
        -PowerShellVersion "5.1" `
        -Tags $manifest.package.metadata.tags
}

# increase version
task version_bump version, {
    $versionParts = $script:Version.split(".")
    [int]$major = $versionParts[0]
    [int]$minor = $versionParts[1]
    [int]$patch = $versionParts[2]
    $patch = $patch + 1
    $script:Version="$major.$minor.$patch"
    
    $manifest = [xml](Get-Content $nuspecPath)
    $manifest.package.metadata.version = $script:Version
    $manifest.Save($nuspecPath)
    $manifestTemplate = [xml](Get-Content "$BuildRoot/tools/nuspec.template")
    $manifestTemplate.package.metadata.version = $script:Version
    $manifestTemplate.Save("$BuildRoot/tools/nuspec.template")

    Update-ModuleManifest -Path "$BuildRoot/$module_name/$module_name.psd1" -ModuleVersion $script:Version
}

task analyze {
    $output = Invoke-ScriptAnalyzer "$BuildRoot/$module_name"
    if($output){
        $output
        throw "Script Analysis Failed"
    }
    Write-Build green "Script Analysis found no errors"
}

task generate_package generate_manifest, {
    New-Item -Path $BuildRoot -Name "dist" -ItemType "directory" -Force | out-null
    Copy-Item -Path "$BuildRoot/$module_name/*.psm1","$BuildRoot/$module_name/*.psd1" -Destination "$BuildRoot/dist/"
    Get-ChildItem "$BuildRoot/$module_name/" -Recurse -include "*net45*" | `
        Select-Object -ExpandProperty Fullname | `
        Where-Object {$_ -notlike "*portable*"} | `
        foreach-object {
            $fullpath = $_
            $relativePath = $fullpath.replace("$BuildRoot\$module_name",".")
            Copy-Item -Path $fullpath -Destination "$BuildRoot\dist\$relativePath" -Recurse
        }

}

task . generate_nuspec, generate_manifest, install_packages, analyze, generate_package

task rebuild clean, generate_manifest, install_packages

task package rebuild, generate_package, analyze
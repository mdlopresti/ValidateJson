param(
    # Custom build root, still the original $BuildRoot by default.
    $BuildRoot = $BuildRoot,
    $module_name = "ValidateJson"
)
$module_name = "ValidateJson"
$nuspecPath = "$BuildRoot/$module_name/$module_name.nuspec"

# Synopsis: Remove temp files.
task clean {
	remove "$module_name/lib/**", "$module_name/$module_name.nuspec", "$module_name/$module_name.psd1"
}
task version {
    $template=[xml](Get-Content "$BuildRoot/tools/nuspec.template")
    $script:Version = $template.package.metadata.version
    Write-Build Green "Version is $script:Version"
}
task fetch_required_packages {
    $script:RequiredPackages = (Import-PowerShellDataFile "$BuildRoot/$module_name/PackageRequirements.psd1")['Packages']
    Write-Build Green $script:RequiredPackages
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

    if(($manifest.package.metadata.SelectNodes("dependencie")).count -ne 0) {
        Write-Build green "HasAttribute"
        $dependencies = $manifest.package.metadata.dependencies.GetAttribute("group")
    }else{
        $dependencies = ($manifest.package.metadata.AppendChild($manifest.CreateElement("dependencies"))).AppendChild($manifest.CreateElement("group"))
    }

    $script:RequiredPackages | foreach-object {
        $stop=$false
        $PackageName = $_['package']
        [int]$currentVersion = $_['version'].split(".")[0]
        $matchedPackages = $script:RequiredPackages | `
            Where-object { $_['package'] -eq $PackageName } | `
            foreach-object {[int]$_['version'].split(".")[0]}
        if($matchedPackages.Length -ne 1) {
            $highestVersion = $matchedPackages|sort -desc| select -first 1
            if($currentVersion -ne $highestVersion ) {
                $stop = $true
            }
        }
        if(-not $stop){
            Write-Build Green ("Adding dependency for "+ $_['package'] + "." + $_['version'])
            $dependencyElement = $manifest.CreateElement("dependency")
            $addedElement = $dependencies.AppendChild($dependencyElement)
            $dependencyElement = $addedElement.SetAttribute("id",$_['package'])
            $dependencyElement = $addedElement.SetAttribute("version",$_['version'])
        }
    }
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

task generate_package generate_nuspec, {
    nuget pack "$BuildRoot/$module_name/"
}

task . generate_nuspec, generate_manifest, install_packages, analyze

task rebuild clean, generate_manifest, install_packages

task package rebuild, generate_package, analyze
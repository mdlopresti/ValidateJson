Install-Module InvokeBuild,PSScriptAnalyzer,platyPS -Scope CurrentUser
Install-Module Pester -Scope CurrentUser -MinimumVersion "5.0.0"

if($(winget list --id Microsoft.NuGet --disable-interactivity --accept-source-agreements|out-string) -like '*No installed package found*') {
    winget install -e --id Microsoft.NuGet --disable-interactivity --accept-source-agreements
}

if((nuget sources | out-string) -notlike '*https://api.nuget.org/v3/index.json*') {
    nuget sources Add -Name 'nuget.org' -Source 'https://api.nuget.org/v3/index.json'
}
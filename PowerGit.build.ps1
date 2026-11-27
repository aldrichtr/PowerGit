<#
  InvokeBuild Script for PowerGit Project
#>

$script:Project = @{
  Name = (Get-Item $PSScriptRoot).Name
  Source = (Join-Path $PSScriptRoot 'source')
  Stage = (Join-Path $PSScriptRoot 'stage')
  Tests = (Join-Path $PSScriptRoot 'tests')
}


task Validate -Before Compile {
  $depModule = Get-PSResource 'PSDepend' -ErrorAction SilentlyContinue

  if ($null -eq $depModule) {
    Write-Build Cyan 'Installing PSDepend'
    Install-PSResource 'PSDepend' -Repository PSGallery
  }

}

task Compile -Before Test {
  dotnet publish -v 'normal'
}

task Test -Before Package {}

task Package -Before Verify {
  $result = Build-Module -SourcePath $Project.Source -Passthru
  if ($null -ne $result) {
    $manifest = $result.Path
    $assemblyDir = (Join-Path $result.ModuleBase 'bin')
    $copiedAssemblies = Get-ChildItem -Path "$assemblyDir/*.dll" |
      Resolve-Path -Relative -RelativeBasePath $result.ModuleBase
    Update-ModuleManifest -Path $manifest -RequiredAssemblies $copiedAssemblies
    $newFormat = ~/.pwsh/scripts/Convert-Manifest.ps1 -Path $manifest
    Write-Build Cyan "Reformating manifest"
    $newFormat | Set-Content -Path $manifest
  }
}

task Verify -Before @('Install', 'Deploy') {}

task Install {}

task Deploy {}

task Clean {
  $cleanDirs = @(
    (Join-Path $BuildRoot 'obj'),
    (Join-Path $Project.Source @($Project.Name, 'bin')),
    (Join-Path $Project.Stage $Project.Name)
  )
  foreach ($d in $cleanDirs) {
    Get-ChildItem -Path $d | Remove-Item -Recurse
  }
}

task PreClean -Before Clean {}
task PostClean -After Clean {}

task . Test

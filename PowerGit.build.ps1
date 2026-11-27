<#
  InvokeBuild Script for PowerGit Project
#>

$private:n = (Get-Item $BuildRoot).Name
$script:Project = @{
  Name = $n
  Artifacts = (Join-Path $PSScriptRoot 'out')
  Source = (Join-Path $PSScriptRoot 'source')
  Stage = (Join-Path $PSScriptRoot 'stage')
  Tests = (Join-Path $PSScriptRoot 'tests')
  Manifest = "$n.psd1"
  Module = "$n.psm1"
}
Remove-Variable 'n' -ErrorAction 'SilentlyContinue'


task Validate -Before Compile {
  $depModule = Get-PSResource 'PSDepend' -ErrorAction SilentlyContinue

  if ($null -eq $depModule) {
    Write-Build Cyan 'Installing PSDepend'
    Install-PSResource 'PSDepend' -Repository PSGallery
  }
  foreach ($dir in @('Artifacts', 'Source', 'Stage', 'Tests')) {
    $prDir = (Join-Path $Project[$dir] $Project.Name)
    if (-not (Test-Path $prDir)) {
      print blue "Creating project $dir directory"
      try {
        $null = New-Item -Path $prDir -ItemType Directory -Force
      } catch {
        $PSCmdlet.ThrowTerminatingError($PSItem)
      }
    }
  }
}

task Compile -Before Test {
  dotnet publish -v 'diagnostic'
}

task Test -Before Package {}

task generateBuildConfig -Before Package {
  $modBuilderConfigPath = (Join-Path $Project.Source 'build.psd1')
  $generatedFileWarning = (@(
    ('#' * 80),
    '## ModuleBuilder Configuration File',
    ('#' * 80),
    '## Do not make changes to this file, it will be overwritten by the build'
    ('#' * 80),
    "## Generated at $(Get-Date -Format 'yyyy.MM.dd HH:mm')"
  ) -join "`n")
  $modBuilderConfig = @{
    OutputDirectory = (Resolve-Path -Path $Project.Stage -Relative -RelativeBasePath $Project.Source)
    UnversionedOutputDirectory = $false
    CopyPaths = @('bin')
    Target = 'CleanBuild'
    SemVer = (dotnet-gitversion | ConvertFrom-Json | Select-Object -ExpandProperty 'SemVer')
    BoilerplateDirectory = (Join-Path $Project.Source '_templates')
    <#
    Version
    Prerelease
    BuildMetadata
    SourceDirectories
    PublicFilter
    IgnoreAlias
    Encoding
    Prefix
    ZeroPadLegacy
    Suffix
    Generators
    Passthru
    #>
  }

  $generatedFileWarning | Set-Content $modBuilderConfigPath
  $modBuilderConfig | ConvertTo-Psd | Add-Content $modBuilderConfigPath
}

task Package -Before Verify {
  try {
    $result = Build-Module -SourcePath $Project.Source -Passthru
  } catch {
    throw $_
  }
  $manifest = $result.Path
  $assemblyDir = (Join-Path $result.ModuleBase 'bin')
  $copiedAssemblies = Get-ChildItem -Path "$assemblyDir/*.dll" |
    Resolve-Path -Relative -RelativeBasePath $result.ModuleBase
  try {
    Update-ModuleManifest -Path $manifest -RequiredAssemblies $copiedAssemblies
  } catch {
    throw "Could not add RequiredAssemblies to manifest`n$_"
  }
  try {
    $newFormat = ~/.pwsh/scripts/Convert-Manifest.ps1 -Path $manifest
    Write-Build Cyan 'Reformating manifest'
    $newFormat | Set-Content -Path $manifest
  } catch {
    throw "Could not reformat manifest"
  }
}

task Verify -Before @('Install', 'Deploy') {}

task Install {}

task Deploy {}

task Clean {
  $cleanDirs = (@(
    (Join-Path $Project.Source @($Project.Name, 'bin')),
    $Project.Stage,
    $Project.Artifacts
  ) | ForEach-Object { "$_\*" })

  $cleanFiles = @(
    (Join-Path $Project.Source 'build.psd1')
  )
  foreach ($t in ($cleanDirs + $cleanFiles)) {
    print Gray "Cleaning $t"
    remove "$t"
  }
}

task PreClean -Before Clean {}
task PostClean -After Clean {}

task . Test

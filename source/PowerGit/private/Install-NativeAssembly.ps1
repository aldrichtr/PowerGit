
using namespace System.IO
using namespace System.Management.Automation
using namespace System.Runtime.InteropServices

function  Install-NativeAssembly {
  <#
  .SYNOPSIS
    "Installs" the LibGit2Sharp.NativeBinaries runtime assembly into the directory specified
  .EXAMPLE
    PS> Install-NativeAssembly -Path "$ModulePath/bin" -OS 'win' -Arch 'x64'
  #>
  [CmdletBinding()]
  param(
    # The path to the `runtimes` directory to install from
    [Parameter(
      Position = 0,
      ValueFromPipeline,
      ValueFromPipelineByPropertyName
    )]
    [Alias('PSPath')]
    [string]$Path,

    # Where to install the assembly to
    [Parameter(
    )]
    [string]$Destination,


    # The Operating System
    [Parameter(
    )]
    [ValidateSet('win', 'osx', 'linux')
    ]
    [Alias('OS')]
    [string]$OperatingSystem,

    # Set the OSArchitecture explicitly.
    # By default, it is determined from the RuntimeInformation
    [Parameter(
    )]
    [Alias('Arch')]
    [OSArchitecture]$OSArchitecture,

    # Force the completion of the operation
    [Parameter(
    )]
    [switch]$Force
  )
  process {
    if (-not ($PSBoundParameters.ContainsKey('Path'))) {
      $root = $ExecutionContext.SessionState.Module.ModuleBase
      if ($null -eq $root) {
        $PSCmdlet.ThrowTerminatingError(
          [ErrorRecord]::new(
            [NullReferenceException]::new('Could not determine Module Path'),
            'ModulePathNotFound',
            [ErrorCategory]::ReadError,
            $null
          ))
      }
      $Path = (Join-Path $root @('bin', 'runtimes'))
    }

    if (-not ($PSBoundParameters.ContainsKey('Destination'))) {
      try {
        $Destination = Get-Item $Path | Select-Object -ExpandProperty Parent
      } catch {
        $PSCmdlet.ThrowTerminatingError($PSItem)
      }
    }

    if (-not ($PSBoundParameters.ContainsKey('OperatingSystem'))) {
      $OperatingSystem = if ($IsMacOS) { 'osx' }
      elseif ($IsLinux) { 'linux' }
      elseif ($IsWindows) { 'win' }
      elseif ($PSVersionTable.PSVersion.Major -lt 6) { 'win' }
      else {
        $PSCmdlet.ThrowTerminatingError(
          [ErrorRecord]::new(
            [NullReferenceException]::new('Could not determine OS'),
            'InvalidOS',
            [ErrorCategory]::InvalidData,
            $null
          ))
      }
    }

    if (-not ($PSBoundParameters.ContainsKey('OSArchitecture'))) {
      $OSArchitecture = [RuntimeInformation]::OSArchitecture.ToString()
    }

    $thisHostRuntime = ('{0}-{1}' -f $OperatingSystem, $OSArchitecture).ToLowerInvariant()
    Write-Verbose "determined runtime is $thisHostRuntime"

    $native = (Join-Path $Path @($thisHostRuntime, 'native'))
    if (-not ($native | Test-Path)) {
      $PSCmdlet.ThrowTerminatingError(
        [ErrorRecord]::new(
          [FileNotFoundException]::new("Could not find runtime at $native"),
          'InvalidRuntimePath',
          [ErrorCategory]::ResourceUnavailable,
          $null
        ))
    }


    ## Finally, we have the path to the Native Runtime and the Destination
    try {
      Get-ChildItem -Path $thisHostRuntime |
        ForEach-Object {
          $rtSource = $_
          $possibleDestination = (Join-Path $Destination $rtSource.Name)
          if ($possibleDestination | Test-Path) {
            if ($Force) {
              Write-Verbose 'Overwriting runtime because -Force was given'
            } else {
              $PSCmdlet.ThrowTerminatingError(
                [ErrorRecord]::new(
                  [Exception]::new('Runtime already exists in Destination. Use -Force to overwrite'),
                  'RuntimeExistsWithoutForce',
                  [ErrorCategory]::ResourceExists,
                  $null
                ))
            }
          }
          Write-Debug "Installing runtime '$rtSource' to '$Destination'"
          $options = @{
            Path = $source
            Destination = $Destination
            Force = $Force
          }
          Copy-Item @options
        }
    } catch {
      $PSCmdlet.ThrowTerminatingError($PSItem)
    }
  }
}

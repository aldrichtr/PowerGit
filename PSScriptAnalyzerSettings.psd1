@{
  Severity = @('Error', 'Warning', 'Information')
  ExcludeRules = @(
    '*DSC*'
  )
  Rules = @{
    PSPlaceOpenBrace = @{
      Enable = $true
      OnSameLine = $true
      NewLineAfter = $true
      IgnoreOneLineBlock = $true
    }

    PSAvoidUsingCmdletAliases = @{
      'allowlist' = @('task')
    }

    PSPlaceCloseBrace = @{
      Enable = $true
      NewLineAfter = $false
      IgnoreOneLineBlock = $true
      NoEmptyLineBefore = $true
    }

    PSUseConsistentIndentation = @{
      Enable = $true
      Kind = 'space'
      IndentationSize = 2
    }

    PSUseConsistentWhitespace = @{
      Enable = $true
      CheckInnerBrace = $true
      CheckOpenBrace = $true
      CheckOpenParen = $true
      CheckOperator = $true
      CheckPipe = $true
      CheckPipeForRedundantWhitespace = $false
      CheckSeparator = $true
      CheckParameter = $false
      IgnoreAssignmentOperatorInsideHashTable = $false
    }

    PSAlignAssignmentStatement = @{
      Enable = $false
    }

    PSUseShouldProcessForStateChangingFunctions = @{
      Enable = $true
    }
  }
}

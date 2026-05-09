#requires -Modules Pester

BeforeAll {
    $modulePath = Join-Path (Join-Path (Join-Path $PSScriptRoot '..') 'src') 'PSCaffeinate'
    $modulePath = Join-Path $modulePath 'PSCaffeinate.psd1'
    Import-Module $modulePath -Force
}

Describe 'Module: PSCaffeinate' {

    Context 'Module loading' {

        It 'imports without error' {
            { Import-Module $modulePath -Force } | Should -Not -Throw
        }

        It 'exports Invoke-Caffeinate' {
            $exportedFunctions = (Get-Module PSCaffeinate).ExportedFunctions.Keys
            $exportedFunctions | Should -Contain 'Invoke-Caffeinate'
        }

        It 'exports the caffeinate alias' {
            $exportedAliases = (Get-Module PSCaffeinate).ExportedAliases.Keys
            $exportedAliases | Should -Contain 'caffeinate'
        }

        It 'alias points to Invoke-Caffeinate' {
            (Get-Alias caffeinate).ReferencedCommand.Name | Should -Be 'Invoke-Caffeinate'
        }
    }

    Context 'Manifest validation' {

        BeforeAll {
            $manifestPath = Join-Path (Join-Path (Join-Path $PSScriptRoot '..') 'src') 'PSCaffeinate'
            $manifestPath = Join-Path $manifestPath 'PSCaffeinate.psd1'
            $manifest = Test-ModuleManifest -Path $manifestPath
        }

        It 'has a valid manifest' {
            $manifest | Should -Not -BeNullOrEmpty
        }

        It 'has a GUID' {
            $manifest.Guid | Should -Not -Be ([guid]::Empty)
        }

        It 'has a version' {
            $manifest.Version | Should -Not -BeNullOrEmpty
        }

        It 'has an author' {
            $manifest.Author | Should -Not -BeNullOrEmpty
        }

        It 'has a description' {
            $manifest.Description | Should -Not -BeNullOrEmpty
        }

        It 'specifies PowerShellVersion' {
            $manifest.PowerShellVersion | Should -Not -BeNullOrEmpty
        }

        It 'specifies CompatiblePSEditions' {
            $manifest.CompatiblePSEditions | Should -Not -BeNullOrEmpty
        }

        It 'has Gallery tags' {
            $manifest.PrivateData.PSData.Tags | Should -Not -BeNullOrEmpty
        }

        It 'has a ProjectUri' {
            $manifest.PrivateData.PSData.ProjectUri | Should -Not -BeNullOrEmpty
        }

        It 'has a LicenseUri' {
            $manifest.PrivateData.PSData.LicenseUri | Should -Not -BeNullOrEmpty
        }

        It 'does not export variables' {
            $manifest.ExportedVariables.Count | Should -Be 0
        }

        It 'does not export cmdlets' {
            $manifest.ExportedCmdlets.Count | Should -Be 0
        }
    }

    Context 'Parameter sets' {

        BeforeAll {
            $command = Get-Command Invoke-Caffeinate
        }

        It 'has an Indefinite parameter set (default)' {
            $command.DefaultParameterSet | Should -Be 'Indefinite'
        }

        It 'has a Timeout parameter set' {
            $command.ParameterSets.Name | Should -Contain 'Timeout'
        }

        It 'has a WaitPid parameter set' {
            $command.ParameterSets.Name | Should -Contain 'WaitPid'
        }

        It 'has a Command parameter set' {
            $command.ParameterSets.Name | Should -Contain 'Command'
        }
    }

    Context 'Parameter aliases' {

        BeforeAll {
            $command = Get-Command Invoke-Caffeinate
        }

        It '-PreventDisplaySleep has alias -d' {
            $command.Parameters['PreventDisplaySleep'].Aliases | Should -Contain 'd'
        }

        It '-PreventIdleSleep has alias -i' {
            $command.Parameters['PreventIdleSleep'].Aliases | Should -Contain 'i'
        }

        It '-PreventSystemSleep has alias -s' {
            $command.Parameters['PreventSystemSleep'].Aliases | Should -Contain 's'
        }

        It '-UserActive has alias -u' {
            $command.Parameters['UserActive'].Aliases | Should -Contain 'u'
        }

        It '-Timeout has alias -t' {
            $command.Parameters['Timeout'].Aliases | Should -Contain 't'
        }

        It '-WaitPid has alias -w' {
            $command.Parameters['WaitPid'].Aliases | Should -Contain 'w'
        }
    }

    Context 'Parameter validation' {

        It 'rejects -Timeout 0' {
            { Invoke-Caffeinate -Timeout 0 } | Should -Throw
        }

        It 'rejects -Timeout -1' {
            { Invoke-Caffeinate -Timeout -1 } | Should -Throw
        }

        It 'rejects -WaitPid 0' {
            { Invoke-Caffeinate -WaitPid 0 } | Should -Throw
        }

        It 'rejects -Command with empty string' {
            { Invoke-Caffeinate -Command '' } | Should -Throw
        }

        It 'rejects -Flags with invalid characters' {
            { Invoke-Caffeinate -Flags 'xyz' -Timeout 1 -WhatIf } | Should -Throw
        }

        It 'accepts -Flags with valid characters' {
            { Invoke-Caffeinate -Flags 'disu' -Timeout 1 -WhatIf } | Should -Not -Throw
        }
    }

    Context 'Bundled -Flags parameter' {

        It '-Flags disu sets all four assertions' {
            $verbose = Invoke-Caffeinate -Flags 'disu' -Timeout 1 -Confirm:$false -Verbose 4>&1
            $verboseText = ($verbose | Out-String)
            $verboseText | Should -Match 'display'
            $verboseText | Should -Match 'system-idle'
            $verboseText | Should -Match 'user-active'
        }

        It '-Flags d sets only display assertion' {
            $verbose = Invoke-Caffeinate -Flags 'd' -Timeout 1 -Confirm:$false -Verbose 4>&1
            $verboseText = ($verbose | Out-String)
            $verboseText | Should -Match 'display'
            $verboseText | Should -Not -Match 'user-active'
        }

        It '-Flags works with -Timeout' {
            $elapsed = Measure-Command { Invoke-Caffeinate -Flags 'di' -Timeout 2 }
            $elapsed.TotalSeconds | Should -BeGreaterOrEqual 1.5
            $elapsed.TotalSeconds | Should -BeLessThan 5
        }

        It '-Flags rejects invalid characters' {
            { Invoke-Caffeinate -Flags 'xyz' -Timeout 1 -WhatIf } | Should -Throw
        }
    }

    Context 'ShouldProcess / -WhatIf' {

        It 'does not assert sleep state when -WhatIf is used' {
            { Invoke-Caffeinate -Timeout 1 -WhatIf } | Should -Not -Throw
        }

        It 'returns immediately with -WhatIf (no sleep)' {
            $elapsed = Measure-Command { Invoke-Caffeinate -Timeout 60 -WhatIf }
            $elapsed.TotalSeconds | Should -BeLessThan 2
        }
    }

    Context 'Timeout mode' {

        It 'runs for approximately the specified duration' {
            $elapsed = Measure-Command { Invoke-Caffeinate -Timeout 2 }
            $elapsed.TotalSeconds | Should -BeGreaterOrEqual 1.5
            $elapsed.TotalSeconds | Should -BeLessThan 5
        }
    }

    Context 'WaitPid mode' {

        It 'warns and returns immediately for a non-existent PID' {
            $elapsed = Measure-Command {
                Invoke-Caffeinate -WaitPid 99999 -WarningVariable warnMsg -WarningAction SilentlyContinue
            }
            $elapsed.TotalSeconds | Should -BeLessThan 3
        }
    }

    Context 'Command mode' {

        It 'runs a command and returns its exit context' {
            Invoke-Caffeinate -Command 'cmd.exe' -ArgumentList '/c', 'echo hello'
            $LASTEXITCODE | Should -Be 0
        }

        It 'passes arguments correctly' {
            $output = Invoke-Caffeinate -Command 'cmd.exe' -ArgumentList '/c', 'echo caffeinate_test_token'
            $output | Should -Contain 'caffeinate_test_token'
        }
    }
}

Describe 'PSScriptAnalyzer' {

    BeforeAll {
        $srcPath = Join-Path (Join-Path (Join-Path $PSScriptRoot '..') 'src') 'PSCaffeinate'
        $analyzerResults = Invoke-ScriptAnalyzer -Path $srcPath -Recurse -Severity Warning, Error
    }

    It 'reports no warnings or errors' {
        $analyzerResults | Should -BeNullOrEmpty
    }
}

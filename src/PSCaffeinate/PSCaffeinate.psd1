@{
    RootModule            = 'PSCaffeinate.psm1'
    ModuleVersion         = '1.0.0'
    GUID                  = 'f3a7d2e1-8b4c-4f9a-b1e5-2c6d3f8a0e7b'

    Author                = 'Ray Piller'
    CompanyName           = ''
    Copyright             = '(c) 2026 Ray Piller. MIT License.'

    Description           = 'PSCaffeinate prevents Windows from sleeping -- a drop-in equivalent of the macOS caffeinate command. Supports all major caffeinate flags (-d, -i, -s, -u), timeout (-t), wait-for-PID (-w), and running a subprocess, using the Win32 SetThreadExecutionState API. Exports Invoke-Caffeinate with the alias caffeinate.'

    PowerShellVersion     = '5.1'
    CompatiblePSEditions  = @('Desktop', 'Core')

    FunctionsToExport     = @('Invoke-Caffeinate')
    AliasesToExport       = @('caffeinate')
    CmdletsToExport       = @()
    VariablesToExport     = @()

    PrivateData = @{
        PSData = @{
            Tags         = @('caffeinate', 'sleep', 'power', 'idle', 'display',
                             'Windows', 'productivity', 'SetThreadExecutionState')
            LicenseUri   = 'https://github.com/VertigoRay/PSCaffeinate/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/VertigoRay/PSCaffeinate'
            ReleaseNotes = 'v1.0.0 - Initial release. Invoke-Caffeinate with alias caffeinate. Flags: -d (display), -i (idle), -s (system), -u (user-active). Modes: indefinite, -t timeout, -w PID, subprocess. ShouldProcess / -WhatIf support. Platform guard for non-Windows PowerShell Core.'
        }
    }
}
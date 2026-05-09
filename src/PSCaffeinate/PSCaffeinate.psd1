@{
    RootModule            = 'PSCaffeinate.psm1'
    ModuleVersion         = '1.1.0'
    GUID                  = 'f3a7d2e1-8b4c-4f9a-b1e5-2c6d3f8a0e7b'

    Author                = 'Ray Piller'
    CompanyName           = ''
    Copyright             = '(c) 2026 Ray Piller. MIT License.'

    Description           = 'PSCaffeinate prevents Windows from sleeping -- a drop-in equivalent of the macOS caffeinate command. Supports all major caffeinate flags (-d, -i, -s, -u), timeout (-t), wait-for-PID (-w), and running a subprocess, using the Win32 SetThreadExecutionState API. Exports Invoke-Caffeinate with the alias caffeinate.'

    PowerShellVersion     = '5.1'
    CompatiblePSEditions  = @('Desktop', 'Core')

    FunctionsToExport     = @('Invoke-Caffeinate', 'caffeinate')
    AliasesToExport       = @()
    CmdletsToExport       = @()
    VariablesToExport     = @()

    PrivateData = @{
        PSData = @{
            Tags         = @('caffeinate', 'sleep', 'power', 'idle', 'display',
                             'Windows', 'productivity', 'SetThreadExecutionState')
            LicenseUri   = 'https://github.com/VertigoRay/PSCaffeinate/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/VertigoRay/PSCaffeinate'
            ReleaseNotes = 'v1.1.0 - Fix: ES_USER_PRESENT is deprecated on modern Windows and caused SetThreadExecutionState to silently fail; -u now substitutes display + idle-sleep prevention. Fix: POSIX-style bundled flags (caffeinate -disu) now work via a wrapper function with hashtable splatting. Added return-value checking and periodic re-assertion of sleep prevention every 30s.'
        }
    }
}
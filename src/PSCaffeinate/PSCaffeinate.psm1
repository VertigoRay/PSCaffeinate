#requires -Version 5.1

if ($PSVersionTable.PSVersion.Major -ge 6 -and -not $IsWindows) {
    throw 'PSCaffeinate requires Windows (uses kernel32.dll SetThreadExecutionState).'
}

#region Win32 interop
if (-not ('PSCaffeinate.NativeMethods' -as [type])) {
    Add-Type -Namespace PSCaffeinate -Name NativeMethods -MemberDefinition @'
        [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public static extern uint SetThreadExecutionState(uint esFlags);
'@
}

Set-Variable -Scope Script -Name ES_CONTINUOUS       -Value ([uint32]2147483648) -Option Constant
Set-Variable -Scope Script -Name ES_SYSTEM_REQUIRED  -Value ([uint32]0x00000001) -Option Constant
Set-Variable -Scope Script -Name ES_DISPLAY_REQUIRED -Value ([uint32]0x00000002) -Option Constant
Set-Variable -Scope Script -Name ES_USER_PRESENT     -Value ([uint32]0x00000004) -Option Constant
#endregion

#region Private helpers
function Clear-SleepAssertion {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param()
    $null = [PSCaffeinate.NativeMethods]::SetThreadExecutionState([uint32]$script:ES_CONTINUOUS)
    Write-Verbose -Message 'caffeinate: assertions released.'
}
#endregion

function Invoke-Caffeinate {
    <#
    .SYNOPSIS
        Prevents Windows from sleeping -- a drop-in equivalent of macOS caffeinate.

    .DESCRIPTION
        Uses the Win32 SetThreadExecutionState API to hold sleep-prevention
        assertions for the duration of a timeout, a subprocess, a waited PID,
        or indefinitely until Ctrl+C.

        Flag semantics mirror macOS caffeinate as closely as Windows allows.
        When no assertion flag (-PreventDisplaySleep, -PreventIdleSleep,
        -PreventSystemSleep, -UserActive) is given, idle-sleep prevention is
        assumed, matching caffeinate's default behaviour.

    .PARAMETER Flags
        POSIX-style bundled flags as a single string. Valid characters: d, i, s, u.
        Example: -Flags disu is equivalent to -d -i -s -u.
        Can be combined with -Timeout, -WaitPid, or -Command.

    .PARAMETER PreventDisplaySleep
        Prevent the display from sleeping (ES_DISPLAY_REQUIRED).
        Alias: -d

    .PARAMETER PreventIdleSleep
        Prevent the system from idle-sleeping (ES_SYSTEM_REQUIRED).
        Alias: -i
        This is the default assertion when no flag is specified.

    .PARAMETER PreventSystemSleep
        Prevent system sleep (maps to ES_SYSTEM_REQUIRED; on macOS this is
        AC-power only, but Windows makes no such distinction).
        Alias: -s

    .PARAMETER UserActive
        Assert that the user is active, resetting the idle and screensaver timers
        (ES_USER_PRESENT).
        Alias: -u

    .PARAMETER Timeout
        Release all assertions after this many seconds.
        Alias: -t
        Cannot be combined with -WaitPid or -Command.

    .PARAMETER WaitPid
        Release assertions when the process with this PID exits.
        Alias: -w
        Cannot be combined with -Timeout or -Command.

    .PARAMETER Command
        Run this executable or script and release assertions when it finishes.
        Pass arguments via -ArgumentList.

    .PARAMETER ArgumentList
        Arguments forwarded to -Command.

    .EXAMPLE
        Invoke-Caffeinate
        Prevent idle sleep indefinitely. Press Ctrl+C to stop.

    .EXAMPLE
        caffeinate -d -t 3600
        Keep the display on for one hour.

    .EXAMPLE
        caffeinate -w (Get-Process robocopy).Id
        Stay awake until the running robocopy process exits.

    .EXAMPLE
        caffeinate python train.py --epochs 100
        Keep the system awake while a Python training script runs.

    .EXAMPLE
        caffeinate -disu
        Bundle all assertion flags POSIX-style.

    .EXAMPLE
        caffeinate -i -s -t 7200
        Hold both idle and system-sleep assertions for two hours.

    .LINK
        https://github.com/VertigoRay/PSCaffeinate
    #>

    [CmdletBinding(DefaultParameterSetName = 'Indefinite', SupportsShouldProcess)]
    param(
        [ValidatePattern('^[disuDISU]+$')]
        [string]$Flags,

        [Alias('d')]
        [switch]$PreventDisplaySleep,

        [Alias('i')]
        [switch]$PreventIdleSleep,

        [Alias('s')]
        [switch]$PreventSystemSleep,

        [Alias('u')]
        [switch]$UserActive,

        [Parameter(ParameterSetName = 'Timeout')]
        [Alias('t')]
        [ValidateRange(1, 2147483647)]
        [int]$Timeout,

        [Parameter(ParameterSetName = 'WaitPid')]
        [Alias('w')]
        [ValidateRange(1, 2147483647)]
        [int]$WaitPid,

        [Parameter(ParameterSetName = 'Command', Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Command,

        [Parameter(ParameterSetName = 'Command', Position = 1, ValueFromRemainingArguments)]
        [string[]]$ArgumentList
    )

    #region Expand bundled flags
    if ($Flags) {
        foreach ($char in $Flags.ToLower().ToCharArray()) {
            switch ($char) {
                'd' { $PreventDisplaySleep = $true }
                'i' { $PreventIdleSleep    = $true }
                's' { $PreventSystemSleep  = $true }
                'u' { $UserActive          = $true }
            }
        }
    }
    #endregion

    #region Build execution-state flags
    [uint32]$executionFlags = $script:ES_CONTINUOUS

    if ($PreventDisplaySleep) { $executionFlags = $executionFlags -bor $script:ES_DISPLAY_REQUIRED }
    if ($UserActive)          { $executionFlags = $executionFlags -bor $script:ES_USER_PRESENT     }

    if ($PreventIdleSleep -or $PreventSystemSleep -or
        (-not $PreventDisplaySleep -and -not $UserActive)) {
        $executionFlags = $executionFlags -bor $script:ES_SYSTEM_REQUIRED
    }

    $assertionNames = [System.Collections.Generic.List[string]]::new()
    if ($executionFlags -band $script:ES_DISPLAY_REQUIRED) { $assertionNames.Add('display')     }
    if ($executionFlags -band $script:ES_SYSTEM_REQUIRED)  { $assertionNames.Add('system-idle') }
    if ($executionFlags -band $script:ES_USER_PRESENT)     { $assertionNames.Add('user-active') }

    $assertionLabel = $assertionNames -join ', '
    #endregion

    if (-not $PSCmdlet.ShouldProcess("sleep assertions [$assertionLabel]", 'Hold')) {
        return
    }

    $null = [PSCaffeinate.NativeMethods]::SetThreadExecutionState([uint32]$executionFlags)
    Write-Verbose -Message "caffeinate: holding [$assertionLabel] sleep assertions"

    try {
        switch ($PSCmdlet.ParameterSetName) {

            'Timeout' {
                Write-Information -MessageData "caffeinate: awake for $Timeout second(s) -- Ctrl+C to stop early." -InformationAction Continue
                $deadline = [datetime]::UtcNow.AddSeconds($Timeout)
                while ([datetime]::UtcNow -lt $deadline) {
                    Start-Sleep -Milliseconds 500
                }
            }

            'WaitPid' {
                $targetProcess = Get-Process -Id $WaitPid -ErrorAction SilentlyContinue
                if ($null -eq $targetProcess) {
                    Write-Warning -Message "caffeinate: PID $WaitPid not found -- releasing immediately."
                    return
                }
                Write-Information -MessageData "caffeinate: waiting for PID $WaitPid ($($targetProcess.ProcessName)) -- Ctrl+C to stop early." -InformationAction Continue
                $targetProcess.WaitForExit()
                Write-Verbose -Message "caffeinate: PID $WaitPid exited with code $($targetProcess.ExitCode)."
            }

            'Command' {
                Write-Information -MessageData "caffeinate: running '$Command $ArgumentList'" -InformationAction Continue
                if ($ArgumentList) {
                    & $Command @ArgumentList
                } else {
                    & $Command
                }
            }

            default {
                Write-Information -MessageData 'caffeinate: running indefinitely -- Ctrl+C to stop.' -InformationAction Continue
                while ($true) { Start-Sleep -Seconds 30 }
            }
        }
    } finally {
        Clear-SleepAssertion
    }
}

function caffeinate {
    <#
    .SYNOPSIS
        Wrapper for Invoke-Caffeinate that supports POSIX-style bundled flags.

    .DESCRIPTION
        Expands arguments like -disu into -Flags disu before calling
        Invoke-Caffeinate, enabling a macOS caffeinate-like CLI experience.

    .EXAMPLE
        caffeinate -disu -t 3600
    #>
    $targetCmd = Get-Command Invoke-Caffeinate -CommandType Function
    $switchNames = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )
    foreach ($p in $targetCmd.Parameters.Values) {
        if ($p.SwitchParameter) {
            $null = $switchNames.Add($p.Name)
            foreach ($a in $p.Aliases) { $null = $switchNames.Add($a) }
        }
    }

    $splatParams = @{}
    $positionalArgs = [System.Collections.Generic.List[object]]::new()

    $i = 0
    while ($i -lt $args.Count) {
        $current = $args[$i]

        if ($current -is [string] -and $current -match '^-([disuDISU]{2,})$') {
            $splatParams['Flags'] = $Matches[1].ToLower()
        }
        elseif ($current -is [string] -and $current -match '^-(.+):(.*)$') {
            $paramName = $Matches[1]
            $rawValue  = $Matches[2]
            if ($rawValue -eq '$true')  { $splatParams[$paramName] = $true }
            elseif ($rawValue -eq '$false') { $splatParams[$paramName] = $false }
            else { $splatParams[$paramName] = $rawValue }
        }
        elseif ($current -is [string] -and $current -match '^-(.+)$') {
            $paramName = $Matches[1]
            if ($switchNames.Contains($paramName)) {
                $splatParams[$paramName] = $true
            }
            elseif (($i + 1) -lt $args.Count) {
                $splatParams[$paramName] = $args[$i + 1]
                $i++
            }
            else {
                $splatParams[$paramName] = $true
            }
        }
        else {
            $positionalArgs.Add($current)
        }

        $i++
    }

    if ($positionalArgs.Count -gt 0) {
        $splatParams['Command'] = $positionalArgs[0]
        if ($positionalArgs.Count -gt 1) {
            $splatParams['ArgumentList'] = @($positionalArgs[1..($positionalArgs.Count - 1)])
        }
    }

    Invoke-Caffeinate @splatParams
}

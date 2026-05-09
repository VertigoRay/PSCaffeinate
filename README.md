# PSCaffeinate

[![CI](https://github.com/VertigoRay/PSCaffeinate/actions/workflows/test.yml/badge.svg)](https://github.com/VertigoRay/PSCaffeinate/actions/workflows/test.yml)
[![version](https://img.shields.io/powershellgallery/v/PSCaffeinate.svg)](https://www.powershellgallery.com/packages/PSCaffeinate)
[![downloads](https://img.shields.io/powershellgallery/dt/PSCaffeinate.svg?label=downloads)](https://www.powershellgallery.com/stats/packages/PSCaffeinate?groupby=Version)

A PowerShell module that prevents Windows from sleeping -- a drop-in equivalent of macOS `caffeinate`.

Uses the Win32 `SetThreadExecutionState` API (the same mechanism used by video players and Teams calls) to hold sleep-prevention assertions.

## Installation

```powershell
Install-Module -Name PSCaffeinate -Scope CurrentUser
```

## Usage

```powershell
# Import (auto-imports if installed via Install-Module)
Import-Module PSCaffeinate
```

### Prevent idle sleep indefinitely (Ctrl+C to stop)

```powershell
caffeinate
```

### Prevent display sleep for one hour

```powershell
caffeinate -d -t 3600
```

### Stay awake while a process runs

```powershell
caffeinate -w (Get-Process robocopy).Id
```

### Stay awake while running a command

Arguments after the command name are forwarded automatically -- no parens needed:

```powershell
caffeinate python train.py --epochs 100
caffeinate robocopy C:\src D:\backup /MIR /MT:8
```

> **Note:** Do _not_ wrap the command in parentheses.
> `caffeinate (python train.py)` would execute `python` immediately
> in a subexpression, defeating the purpose.

### Bundle flags POSIX-style

```powershell
caffeinate -disu
caffeinate -Flags di -t 7200
```

## Parameters

| Parameter | Alias | Description |
|---|---|---|
| `-Flags` | | POSIX-style bundled flags: `disu` = `-d -i -s -u` |
| `-PreventDisplaySleep` | `-d` | Prevent the display from sleeping |
| `-PreventIdleSleep` | `-i` | Prevent system idle sleep (default if no flag given) |
| `-PreventSystemSleep` | `-s` | Prevent system sleep (same as `-i` on Windows) |
| `-UserActive` | `-u` | Assert user is active (resets idle/screensaver timer) |
| `-Timeout` | `-t` | Release after N seconds |
| `-WaitPid` | `-w` | Release when a specific PID exits |
| `-Command` | | Run a command and release when it finishes |
| `-ArgumentList` | | Arguments passed to `-Command` |

### ShouldProcess support

`Invoke-Caffeinate` supports `-WhatIf` and `-Confirm`:

```powershell
caffeinate -d -t 60 -WhatIf
# What if: Performing the operation "Hold" on target "sleep assertions [display, system-idle]".
```

## Requirements

- Windows (uses `kernel32.dll`)
- PowerShell 5.1 or later (Desktop or Core edition)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

[MIT](LICENSE)

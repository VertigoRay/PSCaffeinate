# Contributing to PSCaffeinate

Thanks for your interest in contributing!

## Getting started

1. Fork and clone the repository.
2. Install dev dependencies:

   ```powershell
   Install-Module Pester -Scope CurrentUser -Force -SkipPublisherCheck
   Install-Module PSScriptAnalyzer -Scope CurrentUser -Force
   ```

3. Run the test suite:

   ```powershell
   Invoke-Pester ./tests -Output Detailed
   ```

4. Run the linter:

   ```powershell
   Invoke-ScriptAnalyzer -Path ./src/PSCaffeinate -Recurse -Severity Warning, Error
   ```

## Pull requests

- One feature or fix per PR.
- All Pester tests must pass.
- PSScriptAnalyzer must report zero warnings and errors.
- Follow existing naming conventions: PascalCase for parameters, camelCase for local variables.
- Update `README.md` if you add or change parameters.

## Reporting issues

Open a GitHub issue with:

- Your PowerShell version (`$PSVersionTable`).
- Steps to reproduce.
- Expected vs actual behaviour.

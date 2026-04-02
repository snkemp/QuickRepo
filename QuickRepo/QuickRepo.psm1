#Requires -Version 7.0

# ── dot-source private helpers ────────────────────────────────────────────────
Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" | ForEach-Object { . $_.FullName }

# ── dot-source public functions ───────────────────────────────────────────────
Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1"  | ForEach-Object { . $_.FullName }

# ── alias ─────────────────────────────────────────────────────────────────────
Set-Alias -Name repo -Value Invoke-Repo -Scope Global

# ── tab completions ───────────────────────────────────────────────────────────
$subcommands = @('list', 'save', 'rm', 'rename', 'move')

# Completer for Invoke-Repo (covers the `repo` alias too)
Register-ArgumentCompleter -CommandName 'Invoke-Repo' -ParameterName 'Subcommand' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    $store = Get-RepoStore

    # Merge subcommands + alias names so bare `repo f[tab]` works for both
    $candidates = $subcommands + $store.Keys

    $candidates |
        Where-Object { $_ -like "$wordToComplete*" } |
        Sort-Object |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new(
                $_,
                $_,
                'ParameterValue',
                ($store.ContainsKey($_) ? "$_ → $($store[$_])" : $_)
            )
        }
}

# Arg1 completer: alias names for commands that take an alias as first arg
Register-ArgumentCompleter -CommandName 'Invoke-Repo' -ParameterName 'Arg1' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    # Only complete alias names; for `save` there is no existing alias expected
    $subcommand = $fakeBoundParameters['Subcommand']
    if ($subcommand -eq 'save') { return }

    $store = Get-RepoStore
    $store.Keys |
        Where-Object { $_ -like "$wordToComplete*" } |
        Sort-Object |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new(
                $_,
                $_,
                'ParameterValue',
                "$_ → $($store[$_])"
            )
        }
}

# Native completers for the individual public cmdlets (for direct cmdlet use)
foreach ($cmdlet in @('Enter-Repository','Remove-Repository','Rename-Repository','Set-Repository')) {
    Register-ArgumentCompleter -CommandName $cmdlet -ParameterName 'Name' -ScriptBlock {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
        $store = Get-RepoStore
        $store.Keys |
            Where-Object { $_ -like "$wordToComplete*" } |
            Sort-Object |
            ForEach-Object {
                [System.Management.Automation.CompletionResult]::new(
                    $_,
                    $_,
                    'ParameterValue',
                    "$_ → $($store[$_])"
                )
            }
    }
}

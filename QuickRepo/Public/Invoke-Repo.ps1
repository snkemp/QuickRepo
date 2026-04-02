function Invoke-Repo {
    <#
    .SYNOPSIS
        Entry point for all QuickRepo commands via the `repo` alias.
    .DESCRIPTION
        Dispatches subcommands to the appropriate QuickRepo cmdlets.
        If the first argument is not a recognised subcommand it is treated
        as an alias name and Enter-Repository is called.

        Subcommands:
            list    [filter]            - Get-Repository
            save    <alias> [path]      - Add-Repository
            rm      <alias>             - Remove-Repository
            rename  <alias> <newname>   - Rename-Repository
            move    <alias> [path]      - Set-Repository
            <alias>                     - Enter-Repository (fallback)
    .EXAMPLE
        repo list
    .EXAMPLE
        repo list api*
    .EXAMPLE
        repo save myproject
    .EXAMPLE
        repo save myproject C:\Projects\MyProject
    .EXAMPLE
        repo rm myproject
    .EXAMPLE
        repo rename myproject proj
    .EXAMPLE
        repo move myproject C:\NewPath
    .EXAMPLE
        repo myproject
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string] $Subcommand,

        [Parameter(Position = 1)]
        [string] $Arg1,

        [Parameter(Position = 2)]
        [string] $Arg2
    )

    switch ($Subcommand) {
        'list' {
            if ($Arg1) { Get-Repository -Filter $Arg1 }
            else       { Get-Repository }
        }
        'save' {
            if (-not $Arg1) { throw "Usage: repo save <alias> [path]" }
            if ($Arg2) { Add-Repository -Name $Arg1 -Path $Arg2 }
            else       { Add-Repository -Name $Arg1 }
        }
        'rm' {
            if (-not $Arg1) { throw "Usage: repo rm <alias>" }
            Remove-Repository -Name $Arg1
        }
        'rename' {
            if (-not $Arg1 -or -not $Arg2) { throw "Usage: repo rename <alias> <newname>" }
            Rename-Repository -Name $Arg1 -NewName $Arg2
        }
        'move' {
            if (-not $Arg1) { throw "Usage: repo move <alias> [path]" }
            if ($Arg2) { Set-Repository -Name $Arg1 -Path $Arg2 }
            else       { Set-Repository -Name $Arg1 }
        }
        default {
            # Treat as alias goto
            if (-not $Subcommand) {
                Get-Repository
            } else {
                Enter-Repository -Name $Subcommand
            }
        }
    }
}

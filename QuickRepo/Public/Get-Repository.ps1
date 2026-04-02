function Get-Repository {
    <#
    .SYNOPSIS
        Lists saved repository aliases.
    .DESCRIPTION
        Displays all repository aliases and their associated paths.
        Optionally filters by a wildcard pattern.
    .PARAMETER Filter
        Wildcard pattern to filter alias names (e.g. 'my*').
    .EXAMPLE
        Get-Repository
    .EXAMPLE
        Get-Repository -Filter 'api*'
    .EXAMPLE
        repo list
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string] $Filter = '*'
    )

    $store = Get-RepoStore

    if ($store.Count -eq 0) {
        Write-Host 'No repositories saved. Use `repo save <alias>` to add one.'
        return
    }

    $store.GetEnumerator() |
        Where-Object { $_.Key -like $Filter } |
        Sort-Object Key |
        Select-Object @{ Name = 'Alias'; Expression = { $_.Key } },
                      @{ Name = 'Path';  Expression = { $_.Value } }
}

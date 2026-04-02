function Enter-Repository {
    <#
    .SYNOPSIS
        Changes the current location to the path saved under a repository alias.
    .DESCRIPTION
        Performs Set-Location to the path associated with the given alias.
    .PARAMETER Name
        The alias to navigate to.
    .EXAMPLE
        Enter-Repository -Name myproject
    .EXAMPLE
        repo myproject
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $Name
    )

    $store = Get-RepoStore

    if (-not $store.ContainsKey($Name)) {
        throw "Alias '$Name' not found. Use 'repo list' to see available aliases."
    }

    $path = $store[$Name]

    if (-not (Test-Path $path)) {
        throw "Path '$path' for alias '$Name' no longer exists."
    }

    Set-Location -Path $path
}

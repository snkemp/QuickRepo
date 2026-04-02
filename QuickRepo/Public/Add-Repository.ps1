function Add-Repository {
    <#
    .SYNOPSIS
        Saves a folder path under a named alias.
    .DESCRIPTION
        Creates a new repository alias. If no path is specified, the current
        working directory is used. Throws if the alias already exists unless
        -Force is supplied.
    .PARAMETER Name
        The alias name to save.
    .PARAMETER Path
        The folder path to associate with the alias. Defaults to $PWD.
    .PARAMETER Force
        Overwrites an existing alias without prompting.
    .EXAMPLE
        Add-Repository -Name myproject
    .EXAMPLE
        Add-Repository -Name myproject -Path C:\Projects\MyProject
    .EXAMPLE
        repo save myproject
    .EXAMPLE
        repo save myproject C:\Projects\MyProject
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [Parameter(Position = 1)]
        [string] $Path = $PWD.Path,

        [switch] $Force
    )

    $resolved = Resolve-Path -Path $Path -ErrorAction SilentlyContinue
    if (-not $resolved) {
        throw "Path '$Path' does not exist."
    }
    $cleanPath = $resolved.Path

    $store = Get-RepoStore

    if ($store.ContainsKey($Name) -and -not $Force) {
        throw "Alias '$Name' already exists (points to '$($store[$Name])'). Use -Force to overwrite."
    }

    if ($PSCmdlet.ShouldProcess($Name, "Save repository alias → '$cleanPath'")) {
        $store[$Name] = $cleanPath
        Save-RepoStore -Store $store
        Write-Host "Saved: $Name → $cleanPath"
    }
}

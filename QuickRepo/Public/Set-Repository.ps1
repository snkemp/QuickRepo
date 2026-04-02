function Set-Repository {
    <#
    .SYNOPSIS
        Updates the path for an existing repository alias.
    .DESCRIPTION
        Changes the folder path that an existing alias points to without
        renaming the alias. Throws if the alias does not exist.
    .PARAMETER Name
        The alias whose path should be updated.
    .PARAMETER Path
        The new folder path. Defaults to $PWD.
    .EXAMPLE
        Set-Repository -Name myproject -Path C:\NewLocation\MyProject
    .EXAMPLE
        repo move myproject C:\NewLocation\MyProject
    .EXAMPLE
        repo move myproject   # updates to current directory
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [Parameter(Position = 1)]
        [string] $Path = $PWD.Path
    )

    $resolved = Resolve-Path -Path $Path -ErrorAction SilentlyContinue
    if (-not $resolved) {
        throw "Path '$Path' does not exist."
    }
    $cleanPath = $resolved.Path

    $store = Get-RepoStore

    if (-not $store.ContainsKey($Name)) {
        throw "Alias '$Name' not found. Use 'repo save $Name' to create it."
    }

    $oldPath = $store[$Name]

    if ($PSCmdlet.ShouldProcess($Name, "Move repository alias from '$oldPath' to '$cleanPath'")) {
        $store[$Name] = $cleanPath
        Save-RepoStore -Store $store
        Write-Host "Moved: $Name → $cleanPath (was: $oldPath)"
    }
}

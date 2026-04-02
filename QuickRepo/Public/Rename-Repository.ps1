function Rename-Repository {
    <#
    .SYNOPSIS
        Renames a repository alias key, keeping the path unchanged.
    .DESCRIPTION
        Changes the name of an existing alias without modifying the path it
        points to. Throws if OldName does not exist or NewName is already taken.
    .PARAMETER Name
        The current alias name.
    .PARAMETER NewName
        The new alias name.
    .EXAMPLE
        Rename-Repository -Name oldname -NewName newname
    .EXAMPLE
        repo rename oldname newname
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [Parameter(Mandatory, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $NewName
    )

    $store = Get-RepoStore

    if (-not $store.ContainsKey($Name)) {
        throw "Alias '$Name' not found."
    }

    if ($store.ContainsKey($NewName)) {
        throw "Alias '$NewName' already exists."
    }

    if ($PSCmdlet.ShouldProcess($Name, "Rename repository alias to '$NewName'")) {
        $path = $store[$Name]
        $store.Remove($Name)
        $store[$NewName] = $path
        Save-RepoStore -Store $store
        Write-Host "Renamed: $Name → $NewName (path: $path)"
    }
}

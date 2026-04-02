function Remove-Repository {
    <#
    .SYNOPSIS
        Removes a saved repository alias.
    .DESCRIPTION
        Deletes the named alias from the store. Prompts for confirmation
        unless -Force is specified.
    .PARAMETER Name
        The alias to remove.
    .PARAMETER Force
        Suppresses confirmation prompt.
    .EXAMPLE
        Remove-Repository -Name myproject
    .EXAMPLE
        repo rm myproject
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $Name
    )

    $store = Get-RepoStore

    if (-not $store.ContainsKey($Name)) {
        throw "Alias '$Name' not found."
    }

    if ($PSCmdlet.ShouldProcess($Name, "Remove repository alias (was '$($store[$Name])')")) {
        $store.Remove($Name)
        Save-RepoStore -Store $store
        Write-Host "Removed: $Name"
    }
}

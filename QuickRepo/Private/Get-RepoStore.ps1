function Get-RepoStore {
	<#
    .SYNOPSIS
        Loads the repository alias store from disk.
    .OUTPUTS
        [hashtable] alias → path
    #>
	[CmdletBinding()]
	[OutputType([hashtable])]
	param()

	$storePath = Get-RepoStorePath

	if (-not (Test-Path $storePath)) {
		return @{}
	}

	try {
		$json = Get-Content -Path $storePath -Raw -Encoding UTF8
		$obj  = $json | ConvertFrom-Json
		$hashtable = @{}
		foreach ($property in $obj.PSObject.Properties) {
			$hashtable[$property.Name] = $property.Value
		}
		return $hashtable
	}
	catch {
		Write-Warning "QuickRepo: failed to read store at '$storePath': $_"
		return @{}
	}
}

function Get-RepoStorePath {
	<#
    .SYNOPSIS
        Returns the resolved path to repos.json.
        Respects $env:QUICKREPO_STORE override (used by tests).
    #>
	if ($env:QUICKREPO_STORE) {
		return $env:QUICKREPO_STORE
	}

	$dir = Join-Path $HOME '.quickrepo'
	return Join-Path $dir 'repos.json'
}

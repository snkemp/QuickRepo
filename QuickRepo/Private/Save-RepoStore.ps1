function Save-RepoStore {
	<#
    .SYNOPSIS
        Persists the repository alias hashtable to disk atomically.
    .PARAMETER Store
        The hashtable of alias → path entries to save.
    #>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)]
		[hashtable] $Store
	)

	$storePath = Get-RepoStorePath
	$storeDir = Split-Path $storePath -Parent

	if (-not (Test-Path $storeDir)) {
		New-Item -ItemType Directory -Path $storeDir -Force | Out-Null
	}

	$json = $Store | ConvertTo-Json -Depth 5 -Compress:$false
	$tmpPath = "$storePath.tmp"

	try {
		Set-Content -Path $tmpPath -Value $json -Encoding UTF8 -Force
		Move-Item -Path $tmpPath -Destination $storePath -Force
	}
	catch {
		if (Test-Path $tmpPath) { Remove-Item $tmpPath -Force -ErrorAction SilentlyContinue }
		throw "QuickRepo: failed to save store at '$storePath': $_"
	}
}

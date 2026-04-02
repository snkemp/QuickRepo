#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }

BeforeAll {
    $env:QUICKREPO_STORE = Join-Path $TestDrive 'repos.json'

    . "$PSScriptRoot\..\Private\Get-RepoStore.ps1"
    . "$PSScriptRoot\..\Private\Save-RepoStore.ps1"
    . "$PSScriptRoot\..\Public\Get-Repository.ps1"
}

Describe 'Get-Repository' {
    AfterEach {
        if (Test-Path $env:QUICKREPO_STORE) { Remove-Item $env:QUICKREPO_STORE -Force }
    }

    AfterAll { $env:QUICKREPO_STORE = $null }
    It 'outputs a message when store is empty' {
        $output = Get-Repository 4>&1 | Out-String
        # Write-Host output comes through stream 1 in tests
        Get-Repository *>&1 | Out-String | Should -Match 'No repositories'
    }

    It 'lists all aliases when store has entries' {
        Save-RepoStore -Store @{ alpha = 'C:\alpha'; beta = 'C:\beta' }
        $result = Get-Repository
        $result | Should -Not -BeNullOrEmpty
    }

    It 'filters by wildcard pattern' {
        Save-RepoStore -Store @{ alpha = 'C:\alpha'; beta = 'C:\beta'; another = 'C:\another' }
        $result = Get-Repository -Filter 'a*'
        $result.Alias | Should -Contain 'alpha'
        $result.Alias | Should -Contain 'another'
        $result.Alias | Should -Not -Contain 'beta'
    }

    It 'returns no results when filter matches nothing' {
        Save-RepoStore -Store @{ alpha = 'C:\alpha' }
        $result = Get-Repository -Filter 'z*'
        $result | Should -BeNullOrEmpty
    }
}

#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }

BeforeAll {
    # Point store at a temp file so tests never touch the real store
    $env:QUICKREPO_STORE = Join-Path $TestDrive 'repos.json'

    # Dot-source private helpers directly
    . "$PSScriptRoot\..\Private\Get-RepoStore.ps1"
    . "$PSScriptRoot\..\Private\Save-RepoStore.ps1"
}

Describe 'Get-RepoStore' {
    AfterEach {
        if (Test-Path $env:QUICKREPO_STORE) { Remove-Item $env:QUICKREPO_STORE -Force }
    }
    It 'returns an empty hashtable when no store file exists' {
        $result = Get-RepoStore
        $result | Should -BeOfType [hashtable]
        $result.Count | Should -Be 0
    }

    It 'returns saved entries as a hashtable' {
        $data = @{ foo = 'C:\foo'; bar = 'C:\bar' }
        $data | ConvertTo-Json | Set-Content $env:QUICKREPO_STORE -Encoding UTF8

        $result = Get-RepoStore
        $result['foo'] | Should -Be 'C:\foo'
        $result['bar'] | Should -Be 'C:\bar'
    }

    It 'returns empty hashtable and warns on corrupt JSON' {
        Set-Content $env:QUICKREPO_STORE -Value 'NOT JSON' -Encoding UTF8
        $result = Get-RepoStore -WarningVariable w 3>$null
        $result.Count | Should -Be 0
    }
}

Describe 'Get-RepoStorePath' {
    AfterEach {
        if ($env:QUICKREPO_STORE -and (Test-Path $env:QUICKREPO_STORE)) { Remove-Item $env:QUICKREPO_STORE -Force }
        $env:QUICKREPO_STORE = Join-Path $TestDrive 'repos.json'
    }

    It 'returns QUICKREPO_STORE env override when set' {
        $result = Get-RepoStorePath
        $result | Should -Be $env:QUICKREPO_STORE
    }

    It 'returns default path when env var is not set' {
        $env:QUICKREPO_STORE = $null
        $result = Get-RepoStorePath
        $result | Should -Be (Join-Path $HOME '.quickrepo' 'repos.json')
    }
}

Describe 'Save-RepoStore' {
    AfterEach {
        if (Test-Path $env:QUICKREPO_STORE) { Remove-Item $env:QUICKREPO_STORE -Force }
        $env:QUICKREPO_STORE = Join-Path $TestDrive 'repos.json'
    }
    It 'creates the store file with correct JSON' {
        $store = @{ alpha = 'C:\alpha' }
        Save-RepoStore -Store $store

        Test-Path $env:QUICKREPO_STORE | Should -BeTrue
        $loaded = @{}; (Get-Content $env:QUICKREPO_STORE -Raw | ConvertFrom-Json).PSObject.Properties | ForEach-Object { $loaded[$_.Name] = $_.Value }
        $loaded['alpha'] | Should -Be 'C:\alpha'
    }

    It 'overwrites existing store file' {
        $initial = @{ old = 'C:\old' }
        Save-RepoStore -Store $initial

        $updated = @{ new = 'C:\new' }
        Save-RepoStore -Store $updated

        $loaded = @{}; (Get-Content $env:QUICKREPO_STORE -Raw | ConvertFrom-Json).PSObject.Properties | ForEach-Object { $loaded[$_.Name] = $_.Value }
        $loaded.ContainsKey('old') | Should -BeFalse
        $loaded['new'] | Should -Be 'C:\new'
    }

    It 'creates the directory if it does not exist' {
        $subDir = Join-Path $TestDrive 'newdir'
        $env:QUICKREPO_STORE = Join-Path $subDir 'repos.json'

        Save-RepoStore -Store @{ x = 'C:\x' }

        Test-Path $env:QUICKREPO_STORE | Should -BeTrue
    }

    AfterAll { $env:QUICKREPO_STORE = $null }
}

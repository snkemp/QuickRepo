#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }

BeforeAll {
    $env:QUICKREPO_STORE = Join-Path $TestDrive 'repos.json'

    . "$PSScriptRoot\..\Private\Get-RepoStore.ps1"
    . "$PSScriptRoot\..\Private\Save-RepoStore.ps1"
    . "$PSScriptRoot\..\Public\Rename-Repository.ps1"
}

Describe 'Rename-Repository' {
    AfterEach {
        if (Test-Path $env:QUICKREPO_STORE) { Remove-Item $env:QUICKREPO_STORE -Force }
    }

    AfterAll { $env:QUICKREPO_STORE = $null }
    It 'renames an alias keeping the path' {
        Save-RepoStore -Store @{ oldname = 'C:\mypath' }
        Rename-Repository -Name 'oldname' -NewName 'newname'
        $store = Get-RepoStore
        $store.ContainsKey('oldname') | Should -BeFalse
        $store['newname'] | Should -Be 'C:\mypath'
    }

    It 'throws when source alias does not exist' {
        { Rename-Repository -Name 'ghost' -NewName 'other' } |
            Should -Throw -ExpectedMessage "*not found*"
    }

    It 'throws when target alias name is already taken' {
        Save-RepoStore -Store @{ a = 'C:\a'; b = 'C:\b' }
        { Rename-Repository -Name 'a' -NewName 'b' } |
            Should -Throw -ExpectedMessage "*already exists*"
    }
}

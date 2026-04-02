#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }

BeforeAll {
    $env:QUICKREPO_STORE = Join-Path $TestDrive 'repos.json'

    . "$PSScriptRoot\..\Private\Get-RepoStore.ps1"
    . "$PSScriptRoot\..\Private\Save-RepoStore.ps1"
    . "$PSScriptRoot\..\Public\Remove-Repository.ps1"
}

Describe 'Remove-Repository' {
    AfterEach {
        if (Test-Path $env:QUICKREPO_STORE) { Remove-Item $env:QUICKREPO_STORE -Force }
    }

    AfterAll { $env:QUICKREPO_STORE = $null }
    It 'removes an existing alias' {
        Save-RepoStore -Store @{ gone = 'C:\gone'; keep = 'C:\keep' }
        Remove-Repository -Name 'gone' -Confirm:$false
        $store = Get-RepoStore
        $store.ContainsKey('gone') | Should -BeFalse
        $store.ContainsKey('keep') | Should -BeTrue
    }

    It 'throws when alias does not exist' {
        { Remove-Repository -Name 'ghost' -Confirm:$false } |
            Should -Throw -ExpectedMessage "*not found*"
    }
}

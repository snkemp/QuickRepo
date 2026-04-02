#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }

BeforeAll {
    $env:QUICKREPO_STORE = Join-Path $TestDrive 'repos.json'

    . "$PSScriptRoot\..\Private\Get-RepoStore.ps1"
    . "$PSScriptRoot\..\Private\Save-RepoStore.ps1"
    . "$PSScriptRoot\..\Public\Set-Repository.ps1"

    $script:PathA = Join-Path $TestDrive 'pathA'
    $script:PathB = Join-Path $TestDrive 'pathB'
    New-Item -ItemType Directory -Path $script:PathA -Force | Out-Null
    New-Item -ItemType Directory -Path $script:PathB -Force | Out-Null
}

Describe 'Set-Repository' {
    AfterEach {
        if (Test-Path $env:QUICKREPO_STORE) { Remove-Item $env:QUICKREPO_STORE -Force }
        $env:QUICKREPO_STORE = Join-Path $TestDrive 'repos.json'
    }

    AfterAll { $env:QUICKREPO_STORE = $null }
    It 'updates the path for an existing alias' {
        Save-RepoStore -Store @{ myrepo = $script:PathA }
        Set-Repository -Name 'myrepo' -Path $script:PathB
        $store = Get-RepoStore
        $store['myrepo'] | Should -Be $script:PathB
    }

    It 'throws when alias does not exist' {
        { Set-Repository -Name 'ghost' -Path $script:PathA } |
            Should -Throw -ExpectedMessage "*not found*"
    }

    It 'throws when new path does not exist on disk' {
        Save-RepoStore -Store @{ myrepo = $script:PathA }
        { Set-Repository -Name 'myrepo' -Path 'C:\DoesNotExist\QuickRepoTest' } |
            Should -Throw -ExpectedMessage "*does not exist*"
    }

    It 'defaults to PWD when no path is supplied' {
        Save-RepoStore -Store @{ myrepo = $script:PathA }
        Push-Location $script:PathB
        Set-Repository -Name 'myrepo'
        Pop-Location
        $store = Get-RepoStore
        $store['myrepo'] | Should -Be $script:PathB
    }
}

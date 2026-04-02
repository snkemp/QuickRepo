#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }

BeforeAll {
    $env:QUICKREPO_STORE = Join-Path $TestDrive 'repos.json'

    . "$PSScriptRoot\..\Private\Get-RepoStore.ps1"
    . "$PSScriptRoot\..\Private\Save-RepoStore.ps1"
    . "$PSScriptRoot\..\Public\Add-Repository.ps1"

    # Create a real temp folder so Resolve-Path succeeds
    $script:TempPath = Join-Path $TestDrive 'myrepo'
    New-Item -ItemType Directory -Path $script:TempPath -Force | Out-Null
}

Describe 'Add-Repository' {
    AfterEach {
        if (Test-Path $env:QUICKREPO_STORE) { Remove-Item $env:QUICKREPO_STORE -Force }
    }

    AfterAll { $env:QUICKREPO_STORE = $null }
    It 'saves an alias with an explicit path' {
        Add-Repository -Name 'myrepo' -Path $script:TempPath
        $store = Get-RepoStore
        $store['myrepo'] | Should -Be $script:TempPath
    }

    It 'defaults path to PWD when no path is given' {
        Push-Location $script:TempPath
        Add-Repository -Name 'pwdrepo'
        Pop-Location
        $store = Get-RepoStore
        $store['pwdrepo'] | Should -Be $script:TempPath
    }

    It 'throws when path does not exist' {
        { Add-Repository -Name 'bad' -Path 'C:\DoesNotExist\QuickRepoTest' } |
            Should -Throw -ExpectedMessage "*does not exist*"
    }

    It 'throws when alias already exists without -Force' {
        Add-Repository -Name 'dup' -Path $script:TempPath
        { Add-Repository -Name 'dup' -Path $script:TempPath } |
            Should -Throw -ExpectedMessage "*already exists*"
    }

    It 'overwrites existing alias with -Force' {
        $anotherPath = Join-Path $TestDrive 'another'
        New-Item -ItemType Directory -Path $anotherPath -Force | Out-Null

        Add-Repository -Name 'forced' -Path $script:TempPath
        Add-Repository -Name 'forced' -Path $anotherPath -Force

        $store = Get-RepoStore
        $store['forced'] | Should -Be $anotherPath
    }
}

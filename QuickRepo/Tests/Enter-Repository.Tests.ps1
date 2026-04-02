#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }

BeforeAll {
    $env:QUICKREPO_STORE = Join-Path $TestDrive 'repos.json'

    . "$PSScriptRoot\..\Private\Get-RepoStore.ps1"
    . "$PSScriptRoot\..\Private\Save-RepoStore.ps1"
    . "$PSScriptRoot\..\Public\Enter-Repository.ps1"

    $script:RealPath = Join-Path $TestDrive 'realrepo'
    New-Item -ItemType Directory -Path $script:RealPath -Force | Out-Null
}

Describe 'Enter-Repository' {
    AfterEach {
        if (Test-Path $env:QUICKREPO_STORE) { Remove-Item $env:QUICKREPO_STORE -Force }
    }

    AfterAll { $env:QUICKREPO_STORE = $null }
    It 'calls Set-Location with the stored path' {
        Save-RepoStore -Store @{ myrepo = $script:RealPath }
        Mock Set-Location {}

        Enter-Repository -Name 'myrepo'

        Should -Invoke Set-Location -Times 1 -ParameterFilter { $Path -eq $script:RealPath }
    }

    It 'throws when alias does not exist' {
        { Enter-Repository -Name 'nope' } |
            Should -Throw -ExpectedMessage "*not found*"
    }

    It 'throws when stored path no longer exists on disk' {
        Save-RepoStore -Store @{ deleted = 'C:\NoLongerExists\QuickRepoTest' }
        { Enter-Repository -Name 'deleted' } |
            Should -Throw -ExpectedMessage "*no longer exists*"
    }
}

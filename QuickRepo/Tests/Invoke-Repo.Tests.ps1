#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }

BeforeAll {
    $env:QUICKREPO_STORE = Join-Path $TestDrive 'repos.json'

    . "$PSScriptRoot\..\Private\Get-RepoStore.ps1"
    . "$PSScriptRoot\..\Private\Save-RepoStore.ps1"
    . "$PSScriptRoot\..\Public\Get-Repository.ps1"
    . "$PSScriptRoot\..\Public\Add-Repository.ps1"
    . "$PSScriptRoot\..\Public\Remove-Repository.ps1"
    . "$PSScriptRoot\..\Public\Enter-Repository.ps1"
    . "$PSScriptRoot\..\Public\Rename-Repository.ps1"
    . "$PSScriptRoot\..\Public\Set-Repository.ps1"
    . "$PSScriptRoot\..\Public\Invoke-Repo.ps1"

    $script:RealPath = Join-Path $TestDrive 'realrepo'
    New-Item -ItemType Directory -Path $script:RealPath -Force | Out-Null
}

Describe 'Invoke-Repo dispatch' {
    AfterEach {
        if (Test-Path $env:QUICKREPO_STORE) { Remove-Item $env:QUICKREPO_STORE -Force }
    }

    AfterAll { $env:QUICKREPO_STORE = $null }
    Context 'list' {
        It 'calls Get-Repository with no filter' {
            Mock Get-Repository {}
            Invoke-Repo -Subcommand 'list'
            Should -Invoke Get-Repository -Times 1
        }

        It 'passes filter to Get-Repository' {
            Mock Get-Repository {}
            Invoke-Repo -Subcommand 'list' -Arg1 'my*'
            Should -Invoke Get-Repository -Times 1 -ParameterFilter { $Filter -eq 'my*' }
        }
    }

    Context 'save' {
        It 'calls Add-Repository with name only' {
            Mock Add-Repository {}
            Invoke-Repo -Subcommand 'save' -Arg1 'myalias'
            Should -Invoke Add-Repository -Times 1 -ParameterFilter { $Name -eq 'myalias' }
        }

        It 'calls Add-Repository with name and path' {
            Mock Add-Repository {}
            Invoke-Repo -Subcommand 'save' -Arg1 'myalias' -Arg2 'C:\some\path'
            Should -Invoke Add-Repository -Times 1 -ParameterFilter { $Name -eq 'myalias' -and $Path -eq 'C:\some\path' }
        }

        It 'throws when no alias given' {
            { Invoke-Repo -Subcommand 'save' } | Should -Throw
        }
    }

    Context 'rm' {
        It 'calls Remove-Repository' {
            Mock Remove-Repository {}
            Invoke-Repo -Subcommand 'rm' -Arg1 'myalias'
            Should -Invoke Remove-Repository -Times 1 -ParameterFilter { $Name -eq 'myalias' }
        }

        It 'throws when no alias given' {
            { Invoke-Repo -Subcommand 'rm' } | Should -Throw
        }
    }

    Context 'rename' {
        It 'calls Rename-Repository' {
            Mock Rename-Repository {}
            Invoke-Repo -Subcommand 'rename' -Arg1 'old' -Arg2 'new'
            Should -Invoke Rename-Repository -Times 1 -ParameterFilter { $Name -eq 'old' -and $NewName -eq 'new' }
        }

        It 'throws when args are missing' {
            { Invoke-Repo -Subcommand 'rename' -Arg1 'onlyone' } | Should -Throw
        }
    }

    Context 'move' {
        It 'calls Set-Repository with name and path' {
            Mock Set-Repository {}
            Invoke-Repo -Subcommand 'move' -Arg1 'myalias' -Arg2 'C:\new'
            Should -Invoke Set-Repository -Times 1 -ParameterFilter { $Name -eq 'myalias' -and $Path -eq 'C:\new' }
        }

        It 'calls Set-Repository with name only (defaults to PWD)' {
            Mock Set-Repository {}
            Invoke-Repo -Subcommand 'move' -Arg1 'myalias'
            Should -Invoke Set-Repository -Times 1 -ParameterFilter { $Name -eq 'myalias' }
        }

        It 'throws when no alias given' {
            { Invoke-Repo -Subcommand 'move' } | Should -Throw
        }
    }

    Context 'fallback (goto alias)' {
        It 'calls Enter-Repository when subcommand is an alias name' {
            Mock Enter-Repository {}
            Invoke-Repo -Subcommand 'myalias'
            Should -Invoke Enter-Repository -Times 1 -ParameterFilter { $Name -eq 'myalias' }
        }

        It 'calls Get-Repository when no subcommand given' {
            Mock Get-Repository {}
            Invoke-Repo
            Should -Invoke Get-Repository -Times 1
        }
    }
}

$SetUp = {
    # Remove and store current modules to be able to restore them later.
    $script:_modules = get-module
    $script:_modules | remove-module -erroraction silentlycontinue

    $script:_oldWorkonHome = $env:WORKON_HOME

    $global:__TEMP_WORKON_HOME = CreateTempDir
    $global:__OLD_WORKON_HOME = $env:WORKON_HOME
    $env:WORKON_HOME = $global:__TEMP_WORKON_HOME
    
    $script:pathToModule = "../virtualenvwrapper/VirtualenvWrapperTabExpansion.psm1"
    import-module "../virtualenvwrapper/VirtualenvWrapperTabExpansion.psm1" `
                    -function LetVirtualEnvsThru, GetVirtualEnvCompletions
}

${TestCase_ - Filtering of virtual environments} = {
    
    ${test_ - Let virtual environments through only} = {
        
        [void] (new-item -itemtype 'file' -path "$env:WORKON_HOME/XXX/Scripts/activate.ps1" -force)
        [void] (new-item -itemtype 'file' -path "$env:WORKON_HOME/YYY/Scripts/activate.ps1" -force)
        [void] (new-item -itemtype 'directory' -path "$env:WORKON_HOME/ZZZ/Scripts/" -force)

        $envs = Get-ChildItem $env:WORKON_HOME | LetVirtualEnvsThru | foreach-object { $_.basename }

        $envs.length -eq 2
        # The following would return ,'ZZZ' if there was a match.
        ($envs -eq 'ZZZ').length -eq 0
    }

    makeTestCase
}

${TestCase_ - Completions extraction} = {
    
    ${test_ - Extract with and without prefix} = {
        
        $completions = GetVirtualEnvCompletions
        $completions.length -eq 2
        ($completions -eq 'ZZZ').length -eq 0

        $completions2 = GetVirtualEnvCompletions -lastword 'xXx'
        $completions2 -eq 'XXX'
    }

    makeTestCase
}

${TestCase_ - Restoring of TabExpansion function} = {
    
    ${test_ - Restore TabExpansion} = {
        get-module | remove-module
        $_old = $function:TabExpansion
        import-module $script:pathToModule
        $_old -ne $function:TabExpansion
        get-module | remove-module
        $_old -eq $function:TabExpansion
    }

    makeTestCase
}

$TearDown = {
    # Restore modules.
    get-module | remove-module -erroraction silentlycontinue
    $script:_modules | import-module -erroraction silentlycontinue

    remove-item $env:WORKON_HOME -recurse -force
    $env:WORKON_HOME = $script:_oldWorkonHome
}

makeTestSuite

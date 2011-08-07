$SetUp = {
    # Remove and store current modules to be able to restore them later.
    $script:_modules = get-module
    $script:_modules | remove-module -erroraction silentlycontinue
        
    $global:__TEMP_WORKON_HOME = CreateTempDir
    $global:__OLD_WORKON_HOME = $env:WORKON_HOME
    $env:WORKON_HOME = $global:__TEMP_WORKON_HOME
    remove-module virtualenvwrapper -erroraction silentlycontinue
    import-module "../virtualenvwrapper/support.psm1"
    import-module "../virtualenvwrapper/win.psm1"
    import-module "../virtualenvwrapper/virtualenvwrapper.psm1" -argumentlist "TESTING"
    # We are not testing events here
    unregister-event -sourceidentifier 'VirtualEnvWrapper.*'
    remove-job -name 'VirtualEnvWrapper.*' -force
}

${TestCase_ - MakeVirtualEnvironment} = {

    ${test_ - Fail if environmental problem} = {
        $oldWORKON_HOME = $env:WORKON_HOME
        $env:WORKON_HOME = "./IDONTEXIST"

        try {
            MakeVirtualEnvironment "NEW"
        }
        catch {
            $true
        }

        $env:WORKON_HOME = $oldWORKON_HOME
    }

    ${test_ - Get Help OK} = {
        $a = MakeVirtualEnvironment
        $a[0] -eq "You must provide a DEST_DIR"
    }

    ${test_ - Creates virtual env correctly} = {
        MakeVirtualEnvironment "NEW" > $null
        
        test-path "$env:WORKON_HOME\NEW"
        test-path "$env:WORKON_HOME\NEW\Scripts"
        test-path "$env:WORKON_HOME\NEW\Scripts\activate.ps1"

        deactivate      
    }

    makeTestCase
}

${TestCase_ - ActivateVirtualEnvironment} = {
    ${test_ - Is env var VIRTUAL_ENV set correctly} = {
        SetVirtualEnvironment 'NEW'
        (join-path $env:WORKON_HOME 'NEW') -eq (resolve-path $env:VIRTUAL_ENV).providerpath
    }

    makeTestCase
}

${TestCase_ - RemoveVirtualEnvironment} = {
    
    ${test_ - Fail if no args} = {
        try {
            RemoveVirtualEnvironment
        }
        catch {
            $_.Exception.Message -eq "You must specify a virtual environment name."
        }
    }

    ${test_ - Fail if bad environment} = {
        $oldWORKON_HOME = $env:WORKON_HOME
        $env:WORKON_HOME = ""

        try {
            RemoveVirtualEnvironment "NONE"
        }
        catch [System.IO.IOException] {
            $true
        }

        $env:WORKON_HOME = $oldWORKON_HOME
    }

    ${test_ - Fail if attempt to remove current env} = {

        SetVirtualEnvironment "NEW"

        try {
            RemoveVirtualEnvironment "NEW"
        }
        catch {
            $_.Exception.Message.StartsWith("ERROR: You cannot remove the active environment")
        }
        finally {
            deactivate
        }

    }

    ${test_ - Remove a virtual env} = {
        RemoveVirtualEnvironment "NEW"
        -not (test-path "$env:WORKON_HOME\NEW")
    }

    makeTestCase
}

${TestCase_ - ShowWorkonHomeOptions } = {
    
    ${test_ - Show available environments} = {
        new-item -itemtype f "$env:WORKON_HOME/a/Scripts/activate.ps1" -force > $null
        new-item -itemtype f "$env:WORKON_HOME/b/Scripts/activate.ps1" -force > $null
        new-item -itemtype f "$env:WORKON_HOME/c/Scripts/activate.ps1" -force > $null

        $res = ShowWorkonHomeOptions

        # Make sure we find the envs
        "$($res | foreach-object { $_.name } | sort-object)" -eq "a b c"

        remove-item "$env:WORKON_HOME/a" -recurse -force
        remove-item "$env:WORKON_HOME/b" -recurse -force
        remove-item "$env:WORKON_HOME/c" -recurse -force

    }

    makeTestCase
}

$TearDown = {
    # Restore modules.
    get-module | remove-module -erroraction silentlycontinue

    $env:WORKON_HOME = $global:__OLD_WORKON_HOME
    $script:_modules | foreach-object { import-module $_.name }
    remove-item $global:__TEMP_WORKON_HOME -recurse -force
    remove-item variable:__TEMP_WORKON_HOME
    remove-item variable:__OLD_WORKON_HOME
}

makeTestSuite
$SetUp = {
    $script:_oldWorkonHome = $env:WORKON_HOME

    # Remove and store current modules to be able to restore them later.
    $script:_modules = get-module
    $script:_modules | remove-module -erroraction silentlycontinue
    remove-job 'VirtualEnvWrapper.*' -Force

    # Make sure WORKON_HOME is undefined.
    remove-item env:WORKON_HOME -erroraction silentlycontinue
    import-module "../virtualenvwrapper/support.psm1"
    import-module "../virtualenvwrapper/win.psm1"
    import-module "../virtualenvwrapper/virtualenvwrapper.psm1"
}

# XXX Move somewhere else?
${TestCase_ By default virtualenvwrapper should... - TestCase} = {

    ${test_ - set default WORKON_HOME to expected value} = {
        $env:WORKON_HOME -eq "$HOME/.virtualenvs"
    }

    makeTestCase
}

$TearDown = {
    # Restore modules.
    get-module | remove-module -erroraction silentlycontinue
    $env:WORKON_HOME = $script:_oldWorkonHome
    $script:_modules | foreach-object { import-module $_ } 
    
}

makeTestSuite
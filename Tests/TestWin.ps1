$SetUp = {
    # Remove and store current modules to be able to restore them later.
    $script:_modules = get-module
    $script:_modules | remove-module -erroraction silentlycontinue

    import-module "../virtualenvwrapper/support.psm1"
    import-module "../virtualenvwrapper/win.psm1"        
}

${TestCase_ Add PoSh to virtualenv - TestCase} = {
    ${test_ - Adds activate script to target path.} = {
        $tmpdir = CreateTempDir
        new-item -item d -path "$tmpdir/Scripts" > $null

        add_posh_to_virtualenv "$tmpdir" > $null

        test-path "$tmpdir/Scripts/activate.ps1"

        remove-item $tmpdir -recurse > $null
    }

    ${test_ - Sets up virtualenv correctly.} = {
        $tmpdir = CreateTempDir
        # Fake a virtualenv.
        new-item -item d -path "$tmpdir/One/Scripts" -force > $null

        # Backup what the function modifies.
        $PATH_BKUP = $env:PATH
        function _my_old_virtual_prompt {}
        $function:_my_old_virtual_prompt = $function:prompt

        $env:VIRTUAL_ENV = "$tmpdir/One"
        add_posh_to_virtualenv "$tmpdir/One" > $null
# 
        # function RunHook { $args }
# 
        & "$tmpdir/One/Scripts/activate.ps1" > $null        
# 
        $expected = (resolve-path "$tmpdir/One").providerpath        
        $expected -eq "$env:VIRTUAL_ENV"

        $function:prompt = $function:_my_old_virtual_prompt
        remove-item function:\_my_old_virtual_prompt > $null
        $env:PATH = $PATH_BKUP        
        remove-item $tmpdir -recurse > $null
        remove-item env:VIRTUAL_ENV > $null
    }

    ${test_ - Cleans up properly.} = {
        $tmpdir = CreateTempDir
        # Fake a virtualenv.
        new-item -item d -path "$tmpdir/One/Scripts" -force > $null

        # Backup what the function modifies.
        $PATH_BKUP = $env:PATH
        function _my_old_virtual_prompt {}
        $function:_my_old_virtual_prompt = $function:prompt

        $env:VIRTUAL_ENV = "$tmpdir/One"
        add_posh_to_virtualenv "$tmpdir/One"

        # function RunHook { $args > $null }

        & "$tmpdir/One/Scripts/activate.ps1"

        deactivate

        ($env:PATH -eq $PATH_BKUP)
        ($function:prompt -eq $function:_my_old_virtual_prompt)

        $function:prompt = $function:_my_old_virtual_prompt
        remove-item function:\_my_old_virtual_prompt

        $env:PATH = $PATH_BKUP
        remove-item $tmpdir -recurse
        # remove-item env:VIRTUAL_ENV
    }    

    makeTestCase
}

$TearDown = {
    # Restore modules.
    get-module | foreach-object { remove-module -name $_ }
    $script:_modules | import-module -erroraction silentlycontinue
}

makeTestSuite
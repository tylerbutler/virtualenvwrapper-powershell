$setUpTestSuite = {
    param($logic)

    $_oldWORKON_HOME = $env:WORKON_HOME
    $_oldVIRTUALENVWRAPPER_HOOK_DIR = $VIRTUALENVWRAPPER_HOOK_DIR
    $_oldVirtualEnvWrapperVirtualeEnv = $global:VIRTUALENVWRAPPER_VIRTUALENV

    import-module "./../virtualenvwrapper/support.psm1"

    & $logic

    remove-module "support"
    unregister-event "virtualenvwrapper.*"
    remove-event "virtualenvwrapper.*"

    remove-item env:WORKON_HOME -erroraction "SilentlyContinue"
    remove-item variable:VIRTUALENVWRAPPER_HOOK_DIR -erroraction "SilentlyContinue"
    if ($_oldWORKON_HOME) { $env:WORKON_HOME = $_oldWORKON_HOME }
    if ($_oldVirtualEnvWrapperVirtualeEnv) { $global:VIRTUALENVWRAPPER_VIRTUALENV = $_oldVirtualEnvWrapperVirtualeEnv }
    if ($_oldVIRTUALENVWRAPPER_HOOK_DIR) { $global:VIRTUALENVWRAPPER_HOOK_DIR = $_oldVIRTUALENVWRAPPER_HOOK_DIR }
}

$TestCase_VerifyFunctions = {
    $test_VerifyVirtualEnvWrapperVirtualEnvFailsWhenVariableNotDefined =  {
        remove-item variable:VIRTUALENVWRAPPER_VIRTUALENV -erroraction "SilentlyContinue"
        try {
            VerifyVirtualEnv
            set-psdebug -Step
            $false
        }
        catch {
            if ($_.Exception.message -eq "`$VIRTUALENVWRAPPER_VIRTUALENV is not defined.") {
                $true
            }
            else {
                $false
            }
        }
    }

    $test_VerifiyVirtualenvFailsWhenVirtualEnvIsNotFound = {
        $global:VIRTUALENVWRAPPER_VIRTUALENV = "xyz.zyx"
        try {
            VerifyVirtualEnv
            $false
        }
        catch [system.io.filenotfoundexception] {
            $_.exception.message -eq "ERROR: virtualenvwrapper could not find virtualenv in your PATH."
        }
    }

    $test_VerifiyVirtualenvFailsWhenVirtualEnvIsNotFound = {
        $global:VIRTUALENVWRAPPER_VIRTUALENV = "xyz.zyx"
        try {
            VerifyVirtualEnv
            $false
        }
        catch [system.io.filenotfoundexception] {
            $_.exception.message -eq "ERROR: virtualenvwrapper could not find virtualenv in your PATH."
        }
    }

    $test_VerifiyWorkonHomeThrowsErrorWhenNotDefined = {
        [void] (remove-item env:WORKON_HOME)

        try {
            [void] (VerifyWorkonHome)
            $false
        }
        catch [io.directorynotfoundexception]{
            $true
        }
    }

    $test_VerifiyWorkonHomeThrowsErrorWhenSetToBadDirectory = {
        $env:WORKON_HOME = "XYZ:"

        try {
            [void] (VerifyWorkonHome)
            $false
        }
        catch [io.directorynotfoundexception]{
            $true
        }
    }

    $test_VerifyActiveEnvironmentFailsWithInexistingPath = {
        $env:VIRTUAL_ENV = "XYZ:"

        try {
            [void] (VerifyActiveEnvironment)
            $false
        }
        catch [system.io.ioexception] {
            $true
        }
    }

    $test_VerifyActiveEnvironmentFailsIfVirtualEnvEnvironmentVariableIsNotSet = {
        remove-item env:VIRTUAL_ENV -erroraction "SilentlyContinue"

        try {
            [void] (VerifyActiveEnvironment)
            $false
        }
        catch [system.io.ioexception] {
            $true
        }
    }

    $test_VerifiyWorkonHomeWorksFine = {
        $env:WORKON_HOME = "."

        try {
            [void] (VerifyWorkonHome)
            $true
        }
        catch [io.directorynotfoundexception]{
           $false
        }
    }
    makeTestCase
}

$TestCase_LooksLikeAVirtualEnv = {
    $setUpTestCase = {
        param($Logic)
        $target_1 = "$env:TEMP/VirtualenvWrapperTests/FOO/Scripts/activate.ps1"
        $target_2 = "$env:TEMP/VirtualenvWrapperTests/BAR/Scripts/"
        [void] (new-item -itemtype "f" -path $target_1 -force)
        [void] (new-item -itemtype "d" -path $target_2 -force)

        & $Logic

        remove-item "$env:TEMP/VirtualenvWrapperTests" -recurse -force
    }

    $test_SucceedsWhenItsSupposedTo = {
         get-item "$env:TEMP/VirtualenvWrapperTests/FOO" | LooksLikeAVirtualenv
    }

    $test_FailWhenItsSupposedTo = {
         get-item "$env:TEMP/VirtualenvWrapperTests/BAR" | LooksLikeAVirtualenv
    }

    makeTestCase
}


$TestCase_GetVirtualEnvData = {
    $setUpTestCase = {
        param($Logic)
        $target_1 = "$env:TEMP/VirtualenvWrapperTests/FOO/Scripts/activate.ps1"
        $target_2 = "$env:TEMP/VirtualenvWrapperTests/BAR/Scripts/"
        [void] (new-item -itemtype "f" -path $target_1 -force)
        [void] (new-item -itemtype "d" -path $target_2 -force)

        $env:WORKON_HOME = "$env:TEMP/VirtualenvWrapperTests"

        & $Logic

        remove-item "$env:TEMP/VirtualenvWrapperTests" -recurse -force
    }

    $test_SucceedsWhenItsSupposedTo = {
         $venvs = @(GetVirtualEnvData)
         $venvs.length -eq 1
         $venvs[0].name -eq "FOO"
    }

    makeTestCase
}


$TestCase_NewVirtualEnvData = {
    $setUpTestCase = {
        param($Logic)
        $target_1 = "$env:TEMP/VirtualenvWrapperTests/FOO/Scripts/activate.ps1"
        $target_2 = "$env:TEMP/VirtualenvWrapperTests/BAR/Scripts/"
        $target_3 = "$env:TEMP/VirtualenvWrapperTests/FOO/lib/site-packages"
        [void] (new-item -itemtype "f" -path $target_1 -force)
        [void] (new-item -itemtype "d" -path $target_2 -force)
        [void] (new-item -itemtype "d" -path $target_3 -force)

        & $Logic

        remove-item "$env:TEMP/VirtualenvWrapperTests" -recurse -force
    }

    $test_ProduceData = {
        $data = NewVirtualEnvData "$env:TEMP/VirtualenvWrapperTests/FOO"

        $data.name -eq "foo"
        (resolve-path $data.pathtoscripts).providerpath -eq (get-item (join-path "$env:TEMP/VirtualenvWrapperTests/foo" "scripts")).fullname
        (resolve-path $data.pathtositepackages).providerpath -eq (get-item (join-path "$env:TEMP/VirtualenvWrapperTests/foo" "lib/site-packages")).fullname
    }

    makeTestCase
}


$TestCase_Initialize = {
    $setUpTestCase = {
        param($Logic)
        $target_1 = "$env:TEMP/VirtualenvWrapperTests/"
        [void] (new-item -itemtype "d" -path $target_1 -force)

        remove-item alias:cdproject -erroraction "SilentlyContinue"
        remove-item alias:mkproject -erroraction "SilentlyContinue"
        remove-item alias:setvirtualenvproject -erroraction "SilentlyContinue"

        Initialize
        & $Logic

        remove-item "$env:TEMP/VirtualenvWrapperTests" -recurse -force
    }

    $test_Initialize = {
        $events = get-event "VirtualenvWrapper.*"
        @($events).count -eq 1
    }

    $test_ThatExtensionsAreLoaded = {
        # virtualenvwrapper will load extenions when Initialize runs.
        test-path alias:mkproject
        test-path alias:cdproject
    }

    makeTestCase
}

makeTestSuite

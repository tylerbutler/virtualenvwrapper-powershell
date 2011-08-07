$SetUp = {
    # Remove and store current modules to be able to restore them later.
    $script:_modules = get-module
    $script:_modules | remove-module -erroraction silentlycontinue

    $script:_oldWorkonHome = $env:WORKON_HOME
    import-module "../virtualenvwrapper/support.psm1"        
}

${TestCase_ VerifyWorkonHome } = {

    ${test_ - Fail If WORKON_HOME Does Not Exist} = {
        remove-item env:WORKON_HOME -erroraction silentlycontinue > $null
        try {
            VerifyWorkonHome
        }
        catch [System.IO.DirectoryNotFoundException] {
            $True
        }

        $env:WORKON_HOME = "./IDONTEXIST"
        try {
            VerifyWorkonHome
        }
        catch [System.IO.DirectoryNotFoundException] {
            $True
        }
    }

    ${test_ - Pass If WORKON_HOME Exists} = {
        $tmpfile = [io.path]::GetTempFileName()
        new-item -item d $tmpfile -force > $null
        
        $env:WORKON_HOME = $tmpfile
        try {
            VerifyWorkonHome
        }
        catch [System.IO.DirectoryNotFoundException] {
            $false
        }
        $true

        remove-item $tmpfile > $null
    }

    makeTestCase
}

${TestCase_ - VerifyVirtualEnv } = {
    
    ${test_ - Fail if virtualenv not available} = {
        $global:VIRTUALENVWRAPPER_VIRTUALENV = "./IDONTEXIST"
        try {
            VerifyVirtualEnv
        }
        catch [System.IO.FileNotFoundException] {
            $true
        }
    }

    ${test_ - Succeed if virtualenv is available} = {
        $global:VIRTUALENVWRAPPER_VIRTUALENV = "cmd.exe"
        try {
            VerifyVirtualEnv
        }
        catch {
            $false
        }
        $true
    }

    makeTestCase
}


${TestCase_ - VerifyWorkonEnvironment} = {

    
    ${test_ Fail if target path doesn't exist } = {
        $tmpfile = [io.path]::GetTempFileName()        
        new-item -itemtype d $tmpfile -force > $null

        $env:WORKON_HOME = $tmpfile

        try {
            VerifyWorkonEnvironment "TEST"
        }
        catch [System.IO.DirectoryNotFoundException] {
            $true
        }
        $true

        remove-item $tmpfile
    }

    ${test_ Succeed if target path exists } = {
        $tmpfile = CreateTempDir
        $env:WORKON_HOME = $tmpfile.fullname
        new-item -itemtype d "$env:WORKON_HOME\TEST" -force > $null

        try {
            VerifyWorkonEnvironment "TEST"
        }
        catch [System.IO.DirectoryNotFoundException] {
            $false
        }
        $true

        remove-item $tmpfile -recurse -force
    }    

    makeTestCase
}

${TestCase_ - VerifyActiveEnvironment} = {
    ${test_ - Fail if VIRTUAL_ENV variable doesn't exist} = {
        remove-item env:VIRTUAL_ENV -erroraction silentlycontinue

        try {
            VerifyActiveEnvironment
        }
        catch [System.IO.IOException] {
            $true
        }
    }

    ${test_ - Fail if VIRTUAL_ENV path doesn't exist} = {
        remove-item env:VIRTUAL_ENV -erroraction silentlycontinue

        $tmpfile = [io.path]::GetTempFileName()        
        remove-item $tmpfile
        $env:VIRTUAL_ENV = $tmpfile

        try {
            VerifyActiveEnvironment
        }
        catch [System.IO.IOException] {
            $true
        }
    }

    makeTestCase
}

${TestCase_ - LooksLikeAVirtualEnv } = {

    ${test_ - Fail if venv positive without script } = {
        $pathToTemp = [io.path]::GetTempPath()
        $newFileName = [io.path]::GetRandomFileName()
        $tmpDir = (join-path $pathToTemp $newFileName)
        $tmpdir = new-item -itemtype d -path $tmpDir -force

        ($tmpDir | LooksLikeAVirtualEnv) -eq $null

        new-item -itemtype f -path (join-path $tmpDir "Scripts/activate.ps1") -force

        ($tmpdir | LooksLikeAVirtualEnv).fullname -eq $tmpDir.fullname

        remove-item $tmpDir -force -recurse
    }

    makeTestCase
}

${TestCase_ - NewVirtualEnvData } = {

    ${test_ - Data is created correctly } = {
        $pathToTemp = [io.path]::GetTempPath()
        $newFileName = [io.path]::GetRandomFileName()
        $tmpDir = (join-path $pathToTemp $newFileName)
        $tmpdir = new-item -itemtype d -path $tmpDir -force
        new-item -itemtype f -path (join-path $tmpDir "Scripts/activate.ps1") -force
        new-item -itemtype d -path (join-path $tmpDir "Lib/site-packages") -force

        $x = NewVirtualEnvData $tmpDir
        
        $x.name -eq $tmpDir.name
        $x.PathToScripts -eq (join-path $tmpdir "Scripts")
        $x.PathToSitePackages -eq (join-path $tmpDir "Lib/site-packages")
        $x.PathInfo -eq $tmpDir

        remove-item $tmpDir -force -recurse
    }

    makeTestCase
}


$TearDown = {
    # Restore modules.
    get-module | remove-module -erroraction silentlycontinue
    $env:WORKON_HOME = $script:_oldWorkonHome
    $script:_modules | foreach-object { import-module $_.name }
}

makeTestSuite
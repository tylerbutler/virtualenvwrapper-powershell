#requires -version 2.0
# set-strictmode -version '2.0'

. "$(split-path $MyInvocation.MyCommand.Path -parent)/misc.ps1"



$script:failedTests = @()
$script:totalTests = 0


function getTestVariables {
    param([string]$LikePattern, $Scope)
    # Gets test cases in the parent scope.
    $testCases = (get-variable -scope $Scope) | where-object {
                                                        $_.value -is [scriptblock] -and
                                                        $_.name -like $LikePattern
                                                        }
    $testCases | sort-object -property @{Expression={ $_.value.startposition.start }}
}


function makeTestSuite { 
    getTestVariables "SetUp" -scope 2 -erroraction silentlycontinue
    getTestVariables "TestCase_*" -scope 2
    getTestVariables "TearDown" -scope 2 -erroraction silentlycontinue
}
function makeTestCase { getTestVariables "test_*" -scope 2 }


function doesTestPass {
    param([management.automation.psvariable]$Test)
    all (& $Test.value)
}


function absToRelPath {
    param($Path)
    $cd = (resolve-path ($pwd)).providerpath
    $t = (resolve-path ($path)).providerpath
    if ($t.startswith($cd)) {
        join-path '.' ($t[$cd.length..$t.length] -join '')
    }
    else {
        $t
    }
}


function printErrors {
    foreach ($err in $failedTests){
        write-host ('=' * 80) -foreground DarkGray

        $testSuite, $test = $err["testSuite"], $err["test"]
        "[{0}]::{1}:{2}:{3}:{4}" -f (
                                    (absToRelPath $testSuite.value.file),
                                    $testSuite.name,
                                    $test.name,
                                    $test.value.startposition.startline,
                                    $test.value.startposition.startcolumn
                                )

        write-host ('-' * 80) -foreground DarkGray

        if (-not ($err["error"])) {
            $err["test"].value
        }
        else {
            write-host -foreground red $err["error"]
        }
    }

    write-host ('=' * 80) -foreground DarkGray
    write-host -foreground yellow "  $script:totalTests Test(s)" -nonew
    write-host -foreground darkgray " | " -nonew
    $errCountColor = if ($script:failedTests.count -gt 0) { "Red" } else { "DarkGreen" }
    write-host -foreground $errCountColor "$($failedTests.count) Error(s)" -nonew
    write-host -foreground darkgray " | " -nonew
    write-host -foreground gray "Time: $($args[0].elapsedmilliseconds / 1000)s"
    write-host ('=' * 80) -foreground DarkGray
}


function Invoke-TestSuite {
    param([management.automation.psvariable]$TestSuite)

    $tests = & $TestSuite.value
    foreach ($t in @($tests)) {
        try {
            if (doesTestPass $t) {
                write-host -foreground darkgreen '.' -nonewline
            }
            else {
                write-host -foreground red 'F' -nonewline
                $script:failedTests += @{ "testSuite"=$testSuite; "test"=$t; "error"=$null }
            }
        }
        catch {
            write-host -foreground red 'E' -nonewline
            $script:failedTests += @{ "testSuite"=$testSuite; "test"=$t; "error"=$error[0]}
        }
        finally {
            ++$script:totalTests
        }
    }
    write-host
}


function Invoke-PowerTests {
    param($Path)
    begin {
        # set-strictmode -version '2.0'
        $userErrorAP = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
        $sw = new-object 'system.diagnostics.stopwatch'
        $sw.start()
    }
    process {
        foreach ($p in @($Path)) {
            $testSuite = @(& $p)
            if ($testSuite[0].name -eq "SetUp") {
                $setup = $testSuite[0]
                $testSuite = $testSuite[1..$($testSuite.Length-1)]
            }
            if ($testSuite[-1].name -eq "TearDown") {
                $teardown = $testSuite[-1]
                $testSuite = $testSuite[0..$($testSuite.Length-2)]
            }   

            & { 
                & $setup.value

                foreach ($ts in $testSuite) {
                    invoke-testsuite $ts
                }

                & $teardown.value
            }
        }
    }
    end {
        $sw.stop()
        printErrors $sw
        $ErrorActionPreference = $userErrorAP
        $script:failedTests = @()
        $script:totalTests = 0
    }
}

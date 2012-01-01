. "./powertests/powertests.ps1"
. "./powertests/utils.ps1"

$testSuites = $args
if ($args.length -eq 0)
{
	$testSuites = ,(get-item "Test*.ps1")
}

foreach ($ts in $testSuites)
{
	invoke-powertests $ts
}

# remove-module virtualenvwrapper
# import-module virtualenvwrapper

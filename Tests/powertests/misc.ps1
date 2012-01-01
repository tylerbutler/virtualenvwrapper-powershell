#requires -version 2.0
# set-strictmode -version "2.0"

# XXX: This should probably be a module.

function any {
    param($anArray=@())
    ([bool] $anArray) -and ((@($anArray) -eq $true).length -ne 0)
}


function all {
    param($anArray=@())
    ([bool] $anArray) -and ((@($anArray) -eq $false).length -eq 0)
}


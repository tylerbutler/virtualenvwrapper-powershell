$script:pathToProfile = split-path $profile -parent
$script:pathToUserModules = "$pathToProfile/Modules"

copy-item virtualenvwrapper -dest $pathToUserModules -recurse -force -erroraction silentlycontinue
if (-not $?) { write-host -fore red "Error."; break }

write-host "virtualenvwrapper: Installation complete." -fore darkgreen

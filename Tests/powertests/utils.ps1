function CreateTempDir {
    $fName = [io.path]::GetRandomFileName()
    $TMP = [io.path]::GetTempPath()
    $tmpDir = join-path $TMP $fname

    new-item -itemtype d $tmpDir
}
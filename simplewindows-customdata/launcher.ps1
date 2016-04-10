$arguments = "-FirstParameter helloParameter"
$inputFile = "%SYSTEMDRIVE%\\AzureData\\CustomData.bin"
$outputFile = "%SYSTEMDRIVE%\\AzureData\\CustomDataSetupScript.ps1"
$inputStream = New-Object System.IO.FileStream $inputFile, ([IO.FileMode]::Open), ([IO.FileAccess]::Read), ([IO.FileShare]::Read)
$sr = New-Object System.IO.StreamReader(New-Object System.IO.Compression.GZipStream($inputStream, [System.IO.Compression.CompressionMode]::Decompress))
$sr.ReadToEnd() | Out-File($outputFile)
Invoke-Expression("{0} {1}" -f $outputFile, $arguments)

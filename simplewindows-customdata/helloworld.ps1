[CmdletBinding(DefaultParameterSetName="HelloWorld")]
param(
    [Parameter(ParameterSetName="HelloWorld", Mandatory=$true)]
    [string]
    [ValidateNotNullOrEmpty()]
    $FirstParameter
)

$content = "hello world with parameter $FirstParameter"
$outFile = "{0}\\AzureData\\hello.txt" -f $env:SYSTEMDRIVE
Write-Output($outFile)
$content | Out-File -FilePath $outFile -Encoding ascii
Write-Output("hello world with parameter $FirstParameter")

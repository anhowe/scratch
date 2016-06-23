[CmdletBinding(DefaultParameterSetName="Standard")]
param(
    [string]
    [ValidateNotNullOrEmpty()]
    $SubscriptionId,

    [string]
    [ValidateNotNullOrEmpty()]
    $StorageAccountName,

    [string]
    [ValidateNotNullOrEmpty()]
    $RGname,

    [int]
    $DiskCount=3,

    [string]
    [ValidateNotNullOrEmpty()]
    $ContainerName="datadisk",

    [string]
    [ValidateNotNullOrEmpty()]
    $vmName = "linuxvm",

    [string]
    [ValidateNotNullOrEmpty()]
    $srcDataDisk = "dataDisk0.vhd"
)

Set-AzureRmContext -SubscriptionId $SubscriptionId
$storageKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $RGName -StorageAccountName $StorageAccountName).Key1
$destContext=New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $storageKey

# upload the images
# good article on copying between accounts: https://www.opsgility.com/blog/windows-azure-powershell-reference-guide/copying-vhds-blobs-between-storage-accounts/
#$blob1 = Start-AzureStorageBlobCopy -srcUri $ubuntuSAS -DestContainer $ContainerName -DestBlob $ubuntudailyBlob -DestContext $destContext
# https://ooyprplqchmsk.blob.core.windows.net/dd2/dataDisk0.vhd
For ($i=1; $i -le $DiskCOunt; $i++)
{
  $destblob="dataDisk{0}.vhd" -f $i
  $blob1 = Start-AzureStorageBlobCopy -SrcContainer $ContainerName -SrcBlob $srcDataDisk -SrcContext $destContext -DestContainer $ContainerName -DestBlob $destblob -DestContext $destContext
  $status = $blob1 | Get-AzureStorageBlobCopyState
  While($status.Status -eq "Pending"){
    $status = $blob1 | Get-AzureStorageBlobCopyState
    Start-Sleep 10
    $status
  }
}

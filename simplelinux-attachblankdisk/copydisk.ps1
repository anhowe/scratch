$SubscriptionName="Anthony's Developer Azure Account"
$SubscriptionId="b52fce95-de5f-4b37-afca-db203a5d0b6a"
# source data disk https://j3blrojewuwyo.blob.core.windows.net/datadisk/dataDisk0.vhd
$StageStorageAccountName="j3blrojewuwyo"
$ContainerName="datadisk"
$srcDataDisk="dataDisk0.vhd"
$RGname="anhowe0622a"
#$StageRegion="West US"

Set-AzureRmContext -SubscriptionId $SubscriptionId
# this is bogus
#Set-AzureRmCurrentStorageAccount -ResourceGroupName $RGName -StorageAccountName $StageStorageAccountName
$storageKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $RGName -StorageAccountName $StageStorageAccountName).Key1
$destContext=New-AzureStorageContext -StorageAccountName $StageStorageAccountName -StorageAccountKey $storageKey

# upload the images
# good article on copying between accounts: https://www.opsgility.com/blog/windows-azure-powershell-reference-guide/copying-vhds-blobs-between-storage-accounts/
#$blob1 = Start-AzureStorageBlobCopy -srcUri $ubuntuSAS -DestContainer $ContainerName -DestBlob $ubuntudailyBlob -DestContext $destContext
# https://ooyprplqchmsk.blob.core.windows.net/dd2/dataDisk0.vhd
For ($i=1; $i -lt 20; $i++)
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

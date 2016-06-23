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
    $Lun,

    [string]
    [ValidateNotNullOrEmpty()]
    $ContainerName="datadisk",

    [string]
    [ValidateNotNullOrEmpty()]
    $vmName = "linuxvm"
)

$diskName = "datadisk{0}" -f $lun
$targetVhd = "https://{0}.blob.core.windows.net/{1}/dataDisk{2}.vhd" -f $StorageAccountName, $ContainerName, $lun

Set-AzureRmContext -SubscriptionId $SubscriptionId
$storageKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $RGName -StorageAccountName $StorageAccountName).Key1
$destContext=New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $storageKey

# starting attach / detach in an endless while loop
Write-Output(Get-Date)

Write-Output("({0}) getting vm" -f $counter)
$vm = Get-AzureRmVM -ResourceGroupName $rgName -Name $vmName
Write-Output("({0}) attaching disk at LUN {1}" -f $counter, $lun)
Remove-AzureRmVMDataDisk -VM $vm -Name $diskName
Write-Output("({0}) updating Azure VM (remove)" -f $counter)
$result=Update-AzureRmVM -ResourceGroupName $rgName -VM $vm
if ($result -ne $null)
{
  Write-Output(Get-Date)
  Write-Output("UpdateStatus (add): {0}, {1}, {2}, {3}, {4}" -f $result.StatusCode,$result.Status, $result.RequestId,$result.Error,$result.ErrorText)
}
Get-AzureRmVM -ResourceGroupName $rgName -Name $vmName
Write-Output(Get-Date)

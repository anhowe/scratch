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

    [string]
    [ValidateNotNullOrEmpty()]
    $vmName = "linuxvm"
)

Set-AzureRmContext -SubscriptionId $SubscriptionId
$storageKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $RGName -StorageAccountName $StorageAccountName).Key1
$destContext=New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $storageKey

# starting attach / detach in an endless while loop
Write-Output(Get-Date)
Write-Output("({0}) getting vm" -f $counter)
$vm = Get-AzureRmVM -ResourceGroupName $rgName -Name $vmName

$DiskCount=16
For ($i=$DiskCount; $i -ge 0; $i--)
{
  $diskName = "datadisk{0}" -f $i
  Remove-AzureRmVMDataDisk -VM $vm -Name $diskName
}

$result=Update-AzureRmVM -ResourceGroupName $rgName -VM $vm
if ($result -ne $null)
{
  Write-Output(Get-Date)
  Write-Output("UpdateStatus (remove): {0}, {1}, {2}, {3}, {4}" -f $result.StatusCode,$result.Status, $result.RequestId,$result.Error,$result.ErrorText)
}
Get-AzureRmVM -ResourceGroupName $rgName -Name $vmName
Write-Output(Get-Date)

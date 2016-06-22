$SubscriptionName="Anthony's Developer Azure Account"
$SubscriptionId="b52fce95-de5f-4b37-afca-db203a5d0b6a"
$StageStorageAccountName="j3blrojewuwyo"
$ContainerName="datadisk"
$RGname="anhowe0622a"
$vmName = "linuxvm"
$attach = $false
$lun = 1
$diskName = "datadisk{0}" -f $lun
$targetVhd = "https://{0}.blob.core.windows.net/datadisk/dataDisk{1}.vhd" -f $StageStorageAccountName, $lun

Set-AzureRmContext -SubscriptionId $SubscriptionId
$storageKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $RGName -StorageAccountName $StageStorageAccountName).Key1
$destContext=New-AzureStorageContext -StorageAccountName $StageStorageAccountName -StorageAccountKey $storageKey

# starting attach / detach in an endless while loop
Write-Output(Get-Date)
$counter=0
while($true)
{
  $counter++
  Write-Output("({0}) getting vm" -f $counter)
  $vm = Get-AzureRmVM -ResourceGroupName $rgName -Name $vmName
  Write-Output("({0}) attaching disk at LUN {1}" -f $counter, $lun)
  Add-AzureRmVMDataDisk -VM $vm -Name $diskName -VhdUri $targetVhd -LUN $lun -Caching ReadWrite -CreateOption Attach -DiskSizeInGB $null
  Write-Output("({0}) updating Azure VM (add)" -f $counter)
  $result=Update-AzureRmVM -ResourceGroupName $rgName -VM $vm
  Write-Output($result.StatusCode)
  if($result.StatusCode -ne "OK")
  {
    break
  }
  Write-Output("({0}) dettaching disk at LUN {1}" -f $counter, $lun)
  $vm = Get-AzureRmVM -ResourceGroupName $rgName -Name $vmName
  Remove-AzureRmVMDataDisk -VM $vm -Name $diskName
  Write-Output("({0}) updating Azure VM (remove)" -f $counter)
  $result=Update-AzureRmVM -ResourceGroupName $rgName -VM $vm
  Write-Output($result.StatusCode)
  if($result.StatusCode -ne "OK")
  {
    break
  }
}
Write-Output("failed after {0} attempts" -f $counter)
Write-Output(Get-Date)

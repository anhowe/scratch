$SubscriptionName="Anthony's Developer Azure Account"
$SubscriptionId="b52fce95-de5f-4b37-afca-db203a5d0b6a"
$StageStorageAccountName="j3blrojewuwyo"
Set-AzureRmContext -SubscriptionId $SubscriptionId
$ContainerName="datadisk"
$RGname="anhowe0622a"
$vmName = "linuxvm"

Set-AzureRmContext -SubscriptionId $SubscriptionId
$storageKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $RGName -StorageAccountName $StageStorageAccountName).Key1
$destContext=New-AzureStorageContext -StorageAccountName $StageStorageAccountName -StorageAccountKey $storageKey

# starting attach / detach in an endless while loop
Write-Output("({0}) getting vm" -f $counter)
$vm = Get-AzureRmVM -ResourceGroupName $rgName -Name $vmName
Write-Output("({0}) attaching disk at LUN 1" -f $counter)
Add-AzureRmVMDataDisk -VM $vm -Name "datadisk1" -VhdUri "https://ooyprplqchmsk.blob.core.windows.net/datadisk/dataDisk1.vhd" -LUN 1 -Caching ReadWrite -CreateOption Attach -DiskSizeInGB $null
Write-Output("({0}) updating Azure VM (add)" -f $counter)
$result=Update-AzureRmVM -ResourceGroupName $rgName -VM $vm
Write-Output($result.StatusCode)
$vm = Get-AzureRmVM -ResourceGroupName $rgName -Name $vmName
Write-Output("({0}) dettaching disk at LUN 1" -f $counter)
Remove-AzureRmVMDataDisk -VM $vm -Name "datadisk1"
Write-Output("({0}) updating Azure VM (remove)" -f $counter)
$result=Update-AzureRmVM -ResourceGroupName $rgName -VM $vm
Write-Output($result.StatusCode)
Write-Output(Get-Date)

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
$vm.Tags["Fix"] = "me"
$result=Update-AzureRmVM -ResourceGroupName $rgName -VM $vm
$vm.Tags.Remove("Name")
$result=Update-AzureRmVM -ResourceGroupName $rgName -VM $vm
Get-AzureRmVM -ResourceGroupName $rgName -Name $vmName
Write-Output(Get-Date)

# Attach Blank Disks
The template demonstrates attaching a blank disk using power shell.

# Attach / Detach Disks causing
Here is how to repro the issue described here https://github.com/CatalystCode/azure-flocker-driver/issues/15:

1. Deploy the template https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fanhowe%2Fscratch%2Fmaster%2Fsimplelinux-attachblankdisk%2Fazuredeploy.json

2. go to https://resources.azure.com and for this new VM write down the RGName, storageaccountname, and your subscriptionid to use for the commands below.

3. run `CreateDataDisks.ps1 -SubscriptionId SUBSCRIPTIONID -StorageAccountName STORAGEACCOUNT -RGName RESOURCGROUPNAME`

4. in 3 separate powershell windows run the following 3 commands
 1. `attachLUN.ps1 -SubscriptionId SUBSCRIPTIONID -StorageAccountName STORAGEACCOUNT -RGName RESOURCGROUPNAME -Lun 1`
 2. `attachLUN.ps1 -SubscriptionId SUBSCRIPTIONID -StorageAccountName STORAGEACCOUNT -RGName RESOURCGROUPNAME -Lun 2`
 3. `attachLUN.ps1 -SubscriptionId SUBSCRIPTIONID -StorageAccountName STORAGEACCOUNT -RGName RESOURCGROUPNAME -Lun 3`

5. Watch for errors in the above scripts.  Notice that retrying the failed script fixes the VM provisioning state.

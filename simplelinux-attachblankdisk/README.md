# Attach Blank Disks
The template demonstrates attaching a blank disk using power shell.

# Attach / Detach Disks causing a failed VM
Here is how to repro the issue described here https://github.com/CatalystCode/azure-flocker-driver/issues/15:

1. Deploy the template https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fanhowe%2Fscratch%2Fmaster%2Fsimplelinux-attachblankdisk%2Fazuredeploy.json

2. go to https://resources.azure.com and for this new VM write down the RGName, storageaccountname, and your subscriptionid to use for the commands below.

3. run `CreateDataDisks.ps1 -SubscriptionId SUBSCRIPTIONID -StorageAccountName STORAGEACCOUNT -RGName RESOURCGROUPNAME`

4. in 3 separate powershell windows run the following 3 commands
 1. `attachLUN.ps1 -SubscriptionId SUBSCRIPTIONID -StorageAccountName STORAGEACCOUNT -RGName RESOURCGROUPNAME -Lun 1`
 2. `attachLUN.ps1 -SubscriptionId SUBSCRIPTIONID -StorageAccountName STORAGEACCOUNT -RGName RESOURCGROUPNAME -Lun 2`
 3. `attachLUN.ps1 -SubscriptionId SUBSCRIPTIONID -StorageAccountName STORAGEACCOUNT -RGName RESOURCGROUPNAME -Lun 3`

5. Watch for errors in the above scripts.  Notice that retrying the failed script fixes the VM provisioning state.

# LUN 0 issues

The following article (https://blogs.msdn.microsoft.com/igorpag/2014/10/23/azure-storage-secrets-and-linux-io-optimizations/) says that each SCSI Host Linux must have a disk start at LUN0.  This is part of the SCSI spec and how the Linux Kernel is implemented.

Here are some repros to try to see the impact of the LUN0 issue:

1. Deploy the template https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fanhowe%2Fscratch%2Fmaster%2Fsimplelinux-attachblankdisk%2Fazuredeploy.json

2. go to https://resources.azure.com and for this new VM write down the RGName, storageaccountname, and your subscriptionid to use for the commands below.

3. run `CreateDataDisks.ps1 -SubscriptionId SUBSCRIPTIONID -StorageAccountName STORAGEACCOUNT -RGName RESOURCGROUPNAME -DiskCount 10`

4. start fresh by running `detachAllDisks.ps1 -SubscriptionId SUBSCRIPTIONID -StorageAccountName STORAGEACCOUNT -RGName RESOURCGROUPNAME`

5. SSH to Linux machine, and type `sudo apt-get install lsscsi`, then `sudo lsscsi` and observe only /dev/sr0 (cdrom), /dev/sda (os), and /dev/sdb (ephemeral disk)

6. attach disks from lun0 to lun9
 1. `attachLUN0-9.ps1 -SubscriptionId SUBSCRIPTIONID -StorageAccountName STORAGEACCOUNT -RGName RESOURCGROUPNAME`
 2. on the linux machine, type `sudo lsscsi`, and observe 10 disks.

7. start fresh
 1. `detachAllDisks.ps1 -SubscriptionId SUBSCRIPTIONID -StorageAccountName STORAGEACCOUNT -RGName RESOURCGROUPNAME`
 2. on the linux machine, type `sudo lsscsi`, and observe only the 3 original devices sr0, sda, and sdb

8. attach disks from lun1 to lun9
 1. `attachLUN1-9.ps1 -SubscriptionId SUBSCRIPTIONID -StorageAccountName STORAGEACCOUNT -RGName RESOURCGROUPNAME`
 2. on the linux machine, type `sudo lsscsi`, and observe 7 disks!
 3. to see all disks `attachLUN.ps1 -SubscriptionId SUBSCRIPTIONID -StorageAccountName STORAGEACCOUNT -RGName RESOURCGROUPNAME -Lun 0`
 4. on the linux machine, type `sudo lsscsi`, and observe 10 disks!

9. start fresh
  1. `detachAllDisks.ps1 -SubscriptionId SUBSCRIPTIONID -StorageAccountName STORAGEACCOUNT -RGName RESOURCGROUPNAME`
  2. on the linux machine, type `sudo lsscsi`, and observe only the 3 original devices sr0, sda, and sdb

10. attach disks from lun0 to lun9, remove disk at lun0, add disk at lun10, then add disk at lun0
 1. `attachLUN0-9.ps1 -SubscriptionId SUBSCRIPTIONID -StorageAccountName STORAGEACCOUNT -RGName RESOURCGROUPNAME`
 2. on the linux machine, type `sudo lsscsi`, and observe 10 disks.
 3. `detachLUN.ps1 -SubscriptionId SUBSCRIPTIONID -StorageAccountName STORAGEACCOUNT -RGName RESOURCGROUPNAME -Lun 0`
 4. on the linux machine, type `sudo lsscsi`, and observe 9 disks.
 5. attach disk 10 `attachLUN.ps1 -SubscriptionId SUBSCRIPTIONID -StorageAccountName STORAGEACCOUNT -RGName RESOURCGROUPNAME -Lun 10`
 6. on the linux machine, type `sudo lsscsi`, and observe only 9 disks.  The tenth disk is missing.
 7. attach disk 0 `attachLUN.ps1 -SubscriptionId SUBSCRIPTIONID -StorageAccountName STORAGEACCOUNT -RGName RESOURCGROUPNAME -Lun 0`
 8. on the linux machine, type `sudo lsscsi`, and observe 11 disks.  Everything is correct now that the disk at LUN0 has returned.

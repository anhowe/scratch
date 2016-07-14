# Multi Node Linux Cluster

This demonstrates booting multiple linux machines and shows how to setup an experiment to cause the OS drive to land on SDB1.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fanhowe%2Fscratch%2Fmaster%2Fsimplemultilinux-swapdisks%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

# Repro to swap disks

1. deploy the templateFile using your CLI or clicking deploy to portal above.  Choose one of the multi core machines

2. SSH to the first machine on port 2200 (second machine is on port 2201, 3rd on port 2202, and so on)

3. You need to place your private key in /home/azureuser/ssh
 1. `mkdir ssh`
 2. `cd ssh`
 3. `vi id_rsa` to edit your file and paste in the contents of your private key
 4. `chmod 600 ~/ssh/id_rsa`

4. paste in the contents of `scandrives.sh` and `findr.sh` into `/home/azureuser`

5. `chmod +x /home/azureuser/scandrives.sh`

6. `chmod +x /home/azureuser/findr.sh`

7. `findr.sh`

8. wait until the script breaks out with a repro.

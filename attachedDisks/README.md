# Cloud Init erases attached disks

This template demonstrates the erasure of an attached disk created by cloudinit.  The cloudinit yaml is in `cloudinit.yml`

Edit the parameters and deploy the file.

To repro the erasing disk:
1. once deployed `sudo touch /foo/bar/hello`
2. `sudo ls /foo/bar` and notice the file `hello` exists
3. `sudo reboot`
4. once rebooted, `sudo ls /foo/bar` and notice the file is missing

A similar repro happens when attaching an existing disk to a VM.

This is because of the following bug: https://bugs.launchpad.net/cloud-init/+bug/1692093.

The workaround to this problem is captured in workaround.sh and works the disk is preserved on reboot.
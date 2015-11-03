# Linux VM that takes SSH key

This demonstrates a Linux VM that uses customData to write files, and then the custom script extension to execute them.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fanhowe%2Fscratch%2Fmaster%2FreliableCustomScriptExtension%2FreliableCustomScript.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

# Make the Custom Script Execute Reliably

The customData is used to write the files instead of the VM having to download the files.  The custom script extension is used to execute instead of customData to induce the newtwork failure and then the script is run to handle the network failure.  Alternatively if customData is used to execute, the network failure could come during the middle of the script.

**NOTE: The custom script extension should come last in the dependency chain so that no further network changes will happen while the script runs.**

Here is the procedure for how to implement a reliable script:

Write your shell scripts with “ensureAzureNetwork()” at beginning to protect against 3 types of Azure network errors

```
#!/bin/bash

#######################################
# wait for network to become ready
#######################################
ensureAzureNetwork()
{
  VMNAME=`hostname`
  # ensure the host name is resolvable
  hostResolveHealthy=1
  for i in {1..120}; do
    host $VMNAME
    if [ $? -eq 0 ]
    then
      # hostname has been found continue
      hostResolveHealthy=0
      echo "the host name resolves"
      break
    fi
    sleep 1
  done
  if [ $hostResolveHealthy -ne 0 ]
  then
    echo "host name does not resolve, aborting install"
    exit 1
  fi

  # ensure the network works
  networkHealthy=1
  for i in {1..12}; do
    wget -O/dev/null http://bing.com
    if [ $? -eq 0 ]
    then
      # hostname has been found continue
      networkHealthy=0
      echo "the network is healthy"
      break
    fi
    sleep 10
  done
  if [ $networkHealthy -ne 0 ]
  then
    echo "the network is not healthy, aborting install"
    ifconfig
    ip a
    exit 2
  fi
}
ensureAzureNetwork

#######################################
# run the main program
#######################################
echo hello world
```

Encode your shell scripts into a single line using gen-oneline-customdata.py
```
gen-oneline-customdata.py helloworld.sh
```

Add the resulting output to the "customData" portion of your VM:
```
{
    "apiVersion": "2015-06-15",
    "type": "Microsoft.Compute/virtualMachines",
    "name": "[variables('vmName')]",
    "location": "[resourceGroup().location]",
    "dependsOn": [
        "[concat('Microsoft.Storage/storageAccounts/', parameters('newStorageAccountName'))]",
        "[concat('Microsoft.Network/networkInterfaces/', variables('nicName'))]"
    ],
    "properties": {
        "hardwareProfile": {
            "vmSize": "[variables('vmSize')]"
        },
        "osProfile": {
            "computername": "[variables('vmName')]",
            "adminUsername": "[parameters('adminUsername')]",
            "adminPassword": "[parameters('adminPassword')]",
            "customData": "[base64('#cloud-config\n\nwrite_files:\n -  encoding: gzip\n    content: !!binary |\n        H4sIALvUOFYC/61TTU/DMAy991eYdQeQ2LpxBE1oByQuGxIHLghp6eo20bJkNCkDpv13nKRl2hcMiRzSxnb8nv2c+CxJhUpSZngUxaetKIYlExZyXYJCu9TlDKyGFKd6jlAiyz5OToXKVCUOP2kbh1TnF9EqgmY9jcbD0d1gwrWxis1xQq4Ywi2wHME5wHlAGMI2Wr6xVCKFOc+jN+A9Mmn5x6BPZsdagFCw6ne7/ave+gYy7QF9qnZA9AaRwzO0b6GDr9CDF28jTFXTi6FhBZwZqh8VZa9UBlOtrFAV1oEHmPRqF065htZ2IaEKNK06JqWWzvx/LvzHSMQFuGIyrRxIILoPAx2FNfNv3gFxg5ZpNKC0bWAvgaW6JPoFNclYJmXgge8kuW+giHZFaKbAbYac9fmHtm+6vizQQuchyfAtUZWUwK1dXCduLIsuTdS/KrFDbF+FphIaJh6CflOhtyvDNsZxCXbgnAQ15DEJRE7l5KIIhwWwjTBXQZj1gQf1l3ddVsoLOmek1KLURcnmp79lVxZHKbUbBJlFX0MLLoxdBAAA\n    path: /opt/azure/helloworld.sh\n    permissions: \"0744\"\n\n')]",
            "linuxConfiguration": {
                "disablePasswordAuthentication": "false",
                "ssh": {
                    "publicKeys": [
                        {
                            "path": "[variables('sshKeyPath')]",
                            "keyData": "[parameters('sshKeyData')]"
                        }
                    ]
                }
            }
        },
        "storageProfile": {
            "imageReference": {
                "publisher": "[variables('osImagePublisher')]",
                "offer": "[variables('osImageOffer')]",
                "sku": "[variables('osImageSKU')]",
                "version": "[variables('osImageVersion')]"
            },
            "osDisk": {
                "name": "osdisk",
                "vhd": {
                    "uri": "[concat('http://',parameters('newStorageAccountName'),'.blob.core.windows.net/',variables('vmStorageAccountContainerName'),'/', variables('osDiskName'),'.vhd')]"
                },
                "caching": "ReadWrite",
                "createOption": "FromImage"
            }
        },
        "networkProfile": {
            "networkInterfaces": [
                {
                    "id": "[resourceId('Microsoft.Network/networkInterfaces', variables('nicName'))]"
                }
            ]
        },
        "diagnosticsProfile": {
            "bootDiagnostics": {
                "enabled": "true",
                "storageUri": "[concat('http://',parameters('newStorageAccountName'),'.blob.core.windows.net')]"
            }
        }
    }
}
```

Then run the following in the custom script extension where "bash -c" is used to ensure a log file can be written:
```
{
  "type": "Microsoft.Compute/virtualMachines/extensions",
  "name": "[concat(variables('vmName'), '/configurevm')]",
  "apiVersion": "2015-06-15",
  "location": "[resourceGroup().location]",
  "dependsOn": [
      "[concat('Microsoft.Compute/virtualMachines/', variables('vmName'))]"
  ],
  "properties": {
      "publisher": "Microsoft.OSTCExtensions",
      "type": "CustomScriptForLinux",
      "typeHandlerVersion": "1.3",
      "settings": {
      "fileUris": [],
      "commandToExecute": "/bin/bash -c \"/bin/bash /opt/azure/helloworld.sh >> /var/log/azure/helloworld.log 2>&1\""
      }
  }
}
```

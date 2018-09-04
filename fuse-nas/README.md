# An NFS Filer with an Azure Storage Container backend

The attached template creates an NFS server, and exports the folder of a mounted Azure Storage Container using Azure Blob Fuse https://github.com/Azure/azure-storage-fuse.

Here are the steps to deploy:

1. Ensure you have an already created VNET with a Subnet defined.  You will need the fully qualified Subnet ID.  If you need to create a new VNET, the following "Deploy to Azure" button will create a VNET for you:

   <a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fanhowe%2Fscratch%2Fmaster%2Fvnet%2Fazuredeploy.json" target="_blank">
   <img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.png"/>
   </a>

2. Ensure you have created a storage account capable of supporting block blobs, and created a blob container within that storage account.  Here is a "Deploy to Azure" button that will create a storage account for you.

   <a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAvere%2Fmaster%2Fsrc%2Fstorageaccount%2Fazuredeploy.json" target="_blank">
   <img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.png"/>
   </a>

3. To deploy the NFS server, click the following deploy button, filling in the necessary parameters, using the subnet ID from the previous step:

   <a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fanhowe%2Fscratch%2Fmaster%2Ffuse-nas%2Fazuredeploy.json" target="_blank">
   <img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.png"/>
   </a>

4. Save the Outputs from the client.

5. Install a client machine into the same VNET.  (you may re-use the template above).

6. Using the Find the internal IP address of the NFS server, and save for later. the IP from the output of the server aboveFrom the client machine, add the following line to fstab and mount the container:

```bash
sudo mkdir -p /nfs/blobfuse
sudo chown nobody:nogroup /nfs/blobfuse
echo "10.0.0.4:/nfs/blobfuse    /nfs/blobfuse    nfs hard,nointr,proto=tcp,mountproto=tcp,retry=30 0 0" | sudo tee -a /etc/fstab
sudo mount /nfs/blobfuse
```

7. Now you should be able to list the files in the share, and they will reflect the contents of Azure Storage account container.  Similarly when you write files to the share, you will see them show up in the Azure Storage account container.
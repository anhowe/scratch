# Boot a simple windows VM with customData

This demonstrates booting a simple windows VM using customData to deliver a powershell script for execution on the VM.  This also deploys the custom script extension to execute the script.  The script is gzipped and base64 encoded for most efficient delivery.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fanhowe%2Fscratch%2Fmaster%2Fsimplewindows%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

Here are some notes:
1. Use the gen-ps-launcher-template-vars.py and launcher.ps1 to generate the template variables.  Once generate, put these in the variables section of the template.  The launcher will automatically unzip and launch the powershell in %SYSTEMDRIVE%\AzureData\CustomData.bin.
2. Use the gen-oneline-customdata.py to gzip the powershell script payload.  This gzips the payload for most efficient delivery.  Take the output from this and paste into the customData section of the Windows VM.

The azuredeploy.json demonstrates the launcher and a sample powershell script.  Once you deploy the VM and extension, you can confirm 

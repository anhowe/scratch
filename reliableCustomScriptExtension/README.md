# Linux VM that takes SSH key

This demonstrates a Linux VM that uses customData to write files, and then the custom script extension to execute them.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fanhowe%2Fscratch%2Fmaster%2FreliableCustomScriptExtension%2FreliableCustomScript.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

# Make the Custom Script Execute Reliably

The customData is used to write the files instead of the VM having to download the files.  The custom script extension is used to execute instead of customData to induce the newtwork failure and then the script is run to handle the network failure.  Alternatively if customData is used to execute, the network failure could come during the middle of the script.

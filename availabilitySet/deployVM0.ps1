$VerbosePreference="Continue"
$deployName="anhowe0304asc"
$RGName=$deployName
$locName="Southcentral US"
$templateFile= "azuredeploy.json"
New-AzureRmResourceGroup -Name $RGName -Location $locName -Force
New-AzureRmResourceGroupDeployment -Name $deployName -ResourceGroupName $RGName -TemplateFile $templateFile

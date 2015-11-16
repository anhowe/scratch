$deployName="anhowe1116b"
$RGName=$deployName
$locName="Japan East"
$templateFile= "azuredeploy.json"
$templateParameterFile= "azuredeploy.parameters.json"
Switch-AzureMode -Name AzureResourceManager
New-AzureResourceGroup -Name $RGName -Location $locName -Force

echo New-AzureResourceGroupDeployment -Name $deployName -ResourceGroupName $RGName -TemplateFile $templateFile
New-AzureResourceGroupDeployment -Name $deployName -ResourceGroupName $RGName -TemplateParameterFile $templateParameterFile -TemplateFile $templateFile

$VerbosePreference="Continue"
$deployName="anhowe0329m"
$RGName=$deployName
$locName="West US"
$templateFile= "azuredeploy.json"
$templateParameterFile= "cluster.parameters.json"
New-AzureRmResourceGroup -Name $RGName -Location $locName -Force
New-AzureRmResourceGroupDeployment -Name $deployName -ResourceGroupName $RGName -TemplateParameterFile $templateParameterFile -TemplateFile $templateFile

$VerbosePreference="Continue"
$SubscriptionId="b52fce95-de5f-4b37-afca-db203a5d0b6a"
Set-AzureRmContext -SubscriptionId $SubscriptionId
$deployName="anhowe0622a"
$RGName=$deployName
$locName="West US"
$templateFile= "azuredeploy.json"
$templateParameterFile= "cluster.parameters.json"
New-AzureRmResourceGroup -Name $RGName -Location $locName -Force
New-AzureRmResourceGroupDeployment -Name $deployName -ResourceGroupName $RGName -TemplateParameterFile $templateParameterFile -TemplateFile $templateFile

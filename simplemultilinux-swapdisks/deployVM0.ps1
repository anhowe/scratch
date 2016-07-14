$VerbosePreference="Continue"
$SubscriptionId="b52fce95-de5f-4b37-afca-db203a5d0b6a"
Set-AzureRmContext -SubscriptionId $SubscriptionId
$deployName="anhowe0714a"
$RGName=$deployName
#$locName="East US"
#$locName="brazilsouth"
#$locName="West US"
$locName="East US2"
$templateFile= "azuredeploy.json"
$templateParameterFile= "cluster.parameters.json"
New-AzureRmResourceGroup -Name $RGName -Location $locName -Force
New-AzureRmResourceGroupDeployment -Name $deployName -ResourceGroupName $RGName -TemplateParameterFile $templateParameterFile -TemplateFile $templateFile

$deployName="anhowe1106c"
$RGName=$deployName
$locName="East US2"
$templateFile= "swarm-cluster-with-linux-jumpbox.json"
#$templateFile= "swarm-cluster-with-windows-jumpbox.json"
$templateParameterFile= "cluster.parameters.json"
Switch-AzureMode -Name AzureResourceManager
New-AzureResourceGroup -Name $RGName -Location $locName -Force

echo New-AzureResourceGroupDeployment -Name $deployName -ResourceGroupName $RGName -TemplateParameterFile $templateParameterFile -TemplateFile $templateFile
New-AzureResourceGroupDeployment -Name $deployName -ResourceGroupName $RGName -TemplateParameterFile $templateParameterFile -TemplateFile $templateFile

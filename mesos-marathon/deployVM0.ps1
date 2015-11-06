$deployName="anhowe1106b"
$RGName=$deployName
$locName="East US2"
$templateFile= "mesos-cluster-with-linux-jumpbox.json"
#$templateFile= "mesos-cluster-with-windows-jumpbox.json"
$templateParameterFile= "cluster.parameters.json"
Switch-AzureMode -Name AzureResourceManager
New-AzureResourceGroup -Name $RGName -Location $locName -Force

echo New-AzureResourceGroupDeployment -Name $deployName -ResourceGroupName $RGName -TemplateParameterFile $templateParameterFile -TemplateFile $templateFile
New-AzureResourceGroupDeployment -Name $deployName -ResourceGroupName $RGName -TemplateParameterFile $templateParameterFile -TemplateFile $templateFile

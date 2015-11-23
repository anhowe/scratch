$deployName="anhowe1123d"
$RGName=$deployName
$locName="East US2"
#$templateFile= "mesos-cluster-with-linux-jumpbox.json"
#$templateFile= "mesos-cluster-with-windows-jumpbox.json"
#$templateFile= "mesos-cluster-with-no-jumpbox.json"
$templateFile= "swarm-cluster-with-no-jumpbox.json"
$templateParameterFile= "cluster.parameters.json"
Switch-AzureMode -Name AzureResourceManager
New-AzureResourceGroup -Name $RGName -Location $locName -Force

echo New-AzureResourceGroupDeployment -Name $deployName -ResourceGroupName $RGName -TemplateParameterFile $templateParameterFile -TemplateFile $templateFile
New-AzureResourceGroupDeployment -Name $deployName -ResourceGroupName $RGName -TemplateParameterFile $templateParameterFile -TemplateFile $templateFile

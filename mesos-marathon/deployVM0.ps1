$randomString = [System.Guid]::NewGuid().GetHashCode().ToString("X")

#$templateFile= "mesos-cluster-with-linux-jumpbox.json"
#$templateFile= "mesos-cluster-with-windows-jumpbox.json"
$templateFile= "mesos-cluster-with-no-jumpbox.json"
#$templateFile= "swarm-cluster-with-no-jumpbox.json"
#$templateParameterFile= "cluster.parameters.json"

$deployName="$env:USERNAME$randomString"
$RGName=$deployName
$locName="East US 2"

Switch-AzureMode -Name AzureResourceManager
New-AzureResourceGroup -Name $RGName -Location $locName -Force

$templateParameters = @{ windowsAdminPassword="password1234$";
jumpboxEndpointDNSNamePrefix="testjumpbox$randomString";
masterEndpointDNSNamePrefix="testmaster$randomString";
masterCount=1;
agentEndpointDNSNamePrefix="testagent$randomString";
agentCount=1;
agentVMSize="Standard_A1";
sshRSAPublicKey="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC8fhkh3jpHUQsrUIezFB5k4Rq9giJM8G1Cr0u2IRMiqG++nat5hbOr3gODpTA0h11q9bzb6nJtK7NtDzIHx+w3YNIVpcTGLiUEsfUbY53IHg7Nl/p3/gkST3g0R6BSL7Hg45SfyvpH7kwY30MoVHG/6P3go4SKlYoHXlgaaNr3fMwUTIeE9ofvyS3fcr6xxlsoB6luKuEs50h0NGsE4QEnbfSY4Yd/C1ucc3mEw+QFXBIsENHfHfZYrLNHm2L8MXYVmAH8k//5sFs4Migln9GiUgEQUT6uOjowsZyXBbXwfT11og+syPkAq4eqjiC76r0w6faVihdBYVoc/UcyupgH azureuser@linuxvm"
}

echo New-AzureResourceGroupDeployment -Name $deployName -ResourceGroupName $RGName -TemplateParameterObject $templateParameters -TemplateFile $templateFile
New-AzureResourceGroupDeployment -Name $deployName -ResourceGroupName $RGName -TemplateParameterObject $templateParameters -TemplateFile $templateFile

#echo New-AzureResourceGroupDeployment -Name $deployName -ResourceGroupName $RGName -TemplateParameterFile $templateParameterFile -TemplateFile $templateFile
#New-AzureResourceGroupDeployment -Name $deployName -ResourceGroupName $RGName -TemplateParameterFile $templateParameterFile -TemplateFile $templateFile

# Clusters with Mesos/Marathon/Chronos or Swarm Orchestrators

These Microsoft Azure templates create various cluster combinations with DCOS, or Swarm Orchestrators.  The swarm orchestrator supports linux and windows configurations.

Portal Launch Button|Cluster Type|Walkthrough Instructions
--- | --- | ---
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fanhowe%2Fscratch%2Fmaster%2Facs%2Facsdocs.json" target="_blank"><img src="http://azuredeploy.net/deploybutton.png"/></a>|DCOS|[DCOS Walkthrough](https://github.com/Azure/azure-quickstart-templates/blob/master/101-acs-dcos/docs/DCOSWalkthrough.md)
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fanhowe%2Fscratch%2Fmaster%2Facs%2Facsswarm.json" target="_blank"><img src="http://azuredeploy.net/deploybutton.png"/></a>|Swarm Cluster|[Swarm Cluster Walkthrough](#swarm-cluster-walkthrough)
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fanhowe%2Fscratch%2Fmaster%2Facs%2Facswindows.json" target="_blank"><img src="http://azuredeploy.net/deploybutton.png"/></a>|Swarm Windows Cluster|[Swarm Windows Cluster Walkthrough](#swarm-windows-cluster-walkthrough)

# Swarm Cluster Walkthrough

 Once your cluster has been created you will have a resource group containing 2 parts:

 1. a set of 1,3,5 masters in a master specific availability set.  Each master's SSH can be accessed via the public dns address at ports 2200..2204

 2. a set of agents behind in an agent specific availability set.  The agent VMs must be accessed through the master.

  The following image is an example of a cluster with 3 masters, and 3 agents:

 ![Image of Swarm cluster on azure](https://raw.githubusercontent.com/anhowe/scratch/master/acs/images/swarm.png)

 All VMs are on the same private subnet, 10.0.0.0/18, and fully accessible to each other.

## Explore Swarm with Simple hello world
 1. After successfully deploying the template write down the two output master and agent FQDNs.
 2. SSH to port 2200 of the master FQDN
 3. Type `docker -H :2375 info` to see the status of the agent nodes.
 ![Image of docker info](https://raw.githubusercontent.com/anhowe/scratch/master/acs/images/dockerinfo.png)
 4. Type `docker -H :2375 run -it hello-world` to see the hello-world test app run on one of the agents

## Explore Swarm with a web-based Compose Script, then scale the script to all agents
 1. After successfully deploying the template write down the two output master and agent FQDNs.
 2. create the following docker-compose.yml file with the following content:
```
web:
  image: "yeasy/simple-web"
  ports:
    - "80:80"
  restart: "always"
```
 3.  type `export DOCKER_HOST=:2375` so that docker-compose automatically hits the swarm endpoints
 4. type `docker-compose up -d` to create the simple web server.  this will take about a minute to pull the image
 5. once completed, type `docker ps` to see the running image.
 ![Image of docker ps](https://raw.githubusercontent.com/anhowe/scratch/master/acs/images/dockerps.png)
 6. in your web browser hit the agent FQDN endpoint you recorded in step #1 and you should see the following page, with a counter that increases on each refresh.
 ![Image of the web page](https://raw.githubusercontent.com/anhowe/scratch/master/acs/images/swarmbrowser.png)
 7. You can now scale the web application by typing `docker-compose scale web=3`, and this will scale to the rest of your agents.  The Azure load balancer will automatically pick up the new containers.
 ![Image of docker scaling](https://raw.githubusercontent.com/anhowe/scratch/master/acs/images/dockercomposescale.png)

# Swarm Windows Cluster Walkthrough

Once your Swarm Windows cluster has been created you will have a resource group containing 2 parts:

1. a set of 1,3,5 masters in a master specific availability set.  Each master's SSH can be accessed via the public dns address at ports 2200..2204
2. a set of agents behind in an agent specific availability set.  Each Windows Agent can be access via RDP through ports 3389 for agent0, 3390 for agent1, 3391 for agent2 and so on.

The following image is an example of a cluster with 3 masters, and 3 agents:

![Image of Swarm Windows cluster on azure](https://raw.githubusercontent.com/anhowe/scratch/master/acs/images/swarmwindows.png)

All VMs are on the same private vnet and masters on subnet 172.16.0.0/24, and agents on subnet 10.0.0.0/8, and fully accessible to each other.

## Explore Swarm with Simple hello world
1. After successfully deploying the template write down the two output master and agent FQDNs.
2. SSH to port 2200 of the master FQDN
3. Type `docker -H :2375 info` to see the status of the agent nodes.
![Image of docker info](https://raw.githubusercontent.com/anhowe/scratch/master/acs/images/dockerinfowindows.png)
4. Type `docker -H :2375 run --rm -i windowsservercore powershell -command "Write-Output 'hello world'"` to see the hello-world test app run on one of the agents

## Explore Swarm with a web-based Compose Script, then scale the script to all agents
 1. After successfully deploying the template write down the two output master and agent FQDNs.
 2. type `export DOCKER_HOST=:2375` so that docker-compose automatically hits the swarm endpoints
 3. create the following docker-compose.yml file with the following content:
```
web:
  image: "windowsservercore"
  command: [powershell.exe, -command, "<#code used from https://gist.github.com/wagnerandrade/5424431#> ; $$ip = (Get-NetIPAddress | where {$$_.IPAddress -Like '*.*.*.*'})[0].IPAddress ; $$url = 'http://'+$$ip+':80/' ; $$listener = New-Object System.Net.HttpListener ; $$listener.Prefixes.Add($$url) ; $$listener.Start() ; $$callerCounts = @{} ; Write-Host('Listening at {0}...' -f $$url) ; while ($$listener.IsListening) { ;$$context = $$listener.GetContext() ;$$requestUrl = $$context.Request.Url ;$$clientIP = $$context.Request.RemoteEndPoint.Address ;$$response = $$context.Response ;Write-Host '' ;Write-Host('> {0}' -f $$requestUrl) ;  ;$$count = 1 ;$$k=$$callerCounts.Get_Item($$clientIP) ;if ($$k -ne $$null) { $$count += $$k } ;$$callerCounts.Set_Item($$clientIP, $$count) ;$$header='<html><body><H1>Windows Container Web Server</H1>' ;$$callerCountsString='' ;$$callerCounts.Keys | % { $$callerCountsString+='<p>IP {0} callerCount {1} ' -f $$_,$$callerCounts.Item($$_) } ;$$footer='</body></html>' ;$$content='{0}{1}{2}' -f $$header,$$callerCountsString,$$footer ;Write-Output $$content ;$$buffer = [System.Text.Encoding]::UTF8.GetBytes($$content) ;$$response.ContentLength64 = $$buffer.Length ;$$response.OutputStream.Write($$buffer, 0, $$buffer.Length) ;$$response.Close() ;$$responseStatus = $$response.StatusCode ;Write-Host('< {0}' -f $$responseStatus)  } ; "]
  ports:
    - "80:80"
  restart: "always"
```
 4. type `docker-compose up -d` to create the simple web server.  this will take about a minute to start the image

 5. once completed, type `docker ps` to see the running image.

 ![Image of docker ps](https://raw.githubusercontent.com/anhowe/scratch/master/acs/images/dockerpswindows.png)

 6. in your web browser hit the agent FQDN endpoint you recorded in step #1 and you should see the following page, with a counter that increases on each refresh.

 ![Image of the web page](https://raw.githubusercontent.com/anhowe/scratch/master/acs/images/swarmbrowserwindows.png)

 7. You can now scale the web application by typing `docker-compose scale web=3`, and this will scale to the rest of your agents.  The Azure load balancer will automatically pick up the new containers.

 ![Image of docker scaling](https://raw.githubusercontent.com/anhowe/scratch/master/acs/images/dockercomposescalewindows.png)

# Sample Workloads

Try the following workloads to test your new mesos cluster.  Run these on Marathon using the examples above

1. **Folding@Home** - [docker run rgardler/fah](https://hub.docker.com/r/rgardler/fah/) - Folding@Home is searching for a cure for Cancer, Alzheimers, Parkinsons and other such diseases. Donate some compute time to this fantastic effort.

2. **Mount Azure Files volume within Docker Container** - [docker run --privileged anhowe/azure-file-workload STORAGEACCOUNTNAME STORAGEACCOUNTKEY SHARENAME](https://github.com/anhowe/azure-file-workload) - From each container mount your Azure storage by using Azure files

3. **Explore Docker Hub** - explore Docker Hub for 100,000+ different container workloads: https://hub.docker.com/explore/

# Questions
**Q.** Why is there a jumpbox for the mesos Cluster?

**A.** The jumpbox is used for easy troubleshooting on the private subnet.  The Mesos Web UI requires access to all machines.  Also the web UI.  You could also consider using OpenVPN to access the private subnet.

**Q.** My cluster just completed but Mesos is not up.

**A.** After your template finishes, your cluster is still running installation.  You can run "tail -f /var/log/azure/cluster-bootstrap.log" to verify the status has completed.

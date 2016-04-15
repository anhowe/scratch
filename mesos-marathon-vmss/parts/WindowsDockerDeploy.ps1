<#
    .NOTES
        Copyright (c) Microsoft Corporation.  All rights reserved.

    .SYNOPSIS
        Updates a Windows Server Docker host with latest docker.exe and joins it to a Docker Swarm

    .DESCRIPTION
        Stop Docker
        Opens TCP ports (80,443,2375,8080) in Windows Firewall.
        Updates Windows Docker Binary from DockerPath
        Rewrites runDockerDaemon.cmd startup script to join a Docker Swarm
        Start Docker

    .PARAMETER DockerPath
        Path to a private Docker.exe.  Defaults to https://aka.ms/tp4/docker

    .PARAMETER SwarmMasterIP
        IP Address of Docker Swarm Master

    .EXAMPLE
        .\WindowsDockerDeploy.ps1 

#>
#Requires -Version 5.0

[CmdletBinding(DefaultParameterSetName="IncludeDocker")]
param(
    [Parameter(ParameterSetName="IncludeDocker")]
    [string]
    [ValidateNotNullOrEmpty()]
    $DockerPath = "https://aka.ms/tp4/docker",
    [Parameter(ParameterSetName="IncludeDocker")]
    [string]
    [ValidateNotNullOrEmpty()]
    $SwarmMasterIP = "172.16.0.5"
)

# Stops Docker, Update FireWall Rules, Adds Cluster Info To Docker Config Scrpt, Restart Docker
function Update-ContainerHost()
{
    Test-Admin

    if (-not (Test-Docker))
    {
        throw "Docker service is not running"
    }

    #
    # Stop service
    #
    Stop-Docker

    #
    # Open the firewall
    #
    Write-Output "Opening the firewall ports"
    Open-FirewallPorts

    #
    # Write Docker Script
    #
    Write-DockerStartupScriptWithSwarmClusterInfo

    #
    # Update service
    #
    Write-Output "Updating $global:DockerServiceName..."
    Copy-File -SourcePath $DockerPath -DestinationPath $env:windir\System32\docker.exe

    #
    # Start service
    #
    Start-Docker
}
$global:AdminPriviledges = $false
$global:DockerServiceName = "Docker"

# Get Node IPV4 Address
function Get-IPAddress()
{
    return (Get-NetIPAddress | where {$_.IPAddress -Like '10.*'})[0].IPAddress
}

# Open Windows Firewall Ports Needed
function Open-FirewallPorts()
{
    $ports = @(80,443,2375,8080)
    foreach ($port in $ports)
    {
        $netsh = "netsh advfirewall firewall add rule name='Open Port $port' dir=in action=allow protocol=TCP localport=$port"
        Write-Output "enabling port with command " + $netsh
        Invoke-Expression -Command:$netsh
    }
}

# Update Docker Config to have cluster-store=consul:// address configured for Swarm cluster.
function Write-DockerStartupScriptWithSwarmClusterInfo()
{
    $dataDir = $env:ProgramData

    # create the target directory
    $targetDir = $dataDir + '\docker'
    if(!(Test-Path -Path $targetDir )){
        New-Item -ItemType directory -Path $targetDir
    }

    # overwrite the runDockerDaemon file
    $runDockerFile = $targetDir + "\runDockerDaemon.cmd"
    if(Test-Path -Path $runDockerFile ){
        Copy-Item -Force $runDockerFile "$runDockerFile.bak"
    }
    $ipAddress = Get-IPAddress
    $OutFile = @()
    $OutFile += "@echo off"
    $OutFile += 'docker daemon -D -b "Virtual Switch" -H 0.0.0.0:2375 --cluster-store=consul://' + $SwarmMasterIP + ':8500 --cluster-advertise=' + $ipAddress + ':2375'
    $OutFile | Out-File -encoding ASCII -filepath "$targetDir\runDockerDaemon.cmd"
}

# Copy a file from local filesystem or Internet
function Copy-File
{
    [CmdletBinding()]
    param(
        [string]
        $SourcePath,

        [string]
        $DestinationPath
    )

    if ($SourcePath -eq $DestinationPath)
    {
        return
    }

    if (Test-Path $SourcePath)
    {
        Copy-Item -Path $SourcePath -Destination $DestinationPath
    }
    elseif (($SourcePath -as [System.URI]).AbsoluteURI -ne $null)
    {
        if (Test-Nano)
        {
            $handler = New-Object System.Net.Http.HttpClientHandler
            $client = New-Object System.Net.Http.HttpClient($handler)
            $client.Timeout = New-Object System.TimeSpan(0, 30, 0)
            $cancelTokenSource = [System.Threading.CancellationTokenSource]::new()
            $responseMsg = $client.GetAsync([System.Uri]::new($SourcePath), $cancelTokenSource.Token)
            $responseMsg.Wait()

            if (!$responseMsg.IsCanceled)
            {
                $response = $responseMsg.Result
                if ($response.IsSuccessStatusCode)
                {
                    $downloadedFileStream = [System.IO.FileStream]::new($DestinationPath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
                    $copyStreamOp = $response.Content.CopyToAsync($downloadedFileStream)
                    $copyStreamOp.Wait()
                    $downloadedFileStream.Close()
                    if ($copyStreamOp.Exception -ne $null)
                    {
                        throw $copyStreamOp.Exception
                    }
                }
            }
        }
        elseif ($PSVersionTable.PSVersion.Major -ge 5)
        {
            #
            # We disable progress display because it kills performance for large downloads (at least on 64-bit PowerShell)
            #
            $ProgressPreference = 'SilentlyContinue'
            wget -Uri $SourcePath -OutFile $DestinationPath -UseBasicParsing
            $ProgressPreference = 'Continue'
        }
        else
        {
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFile($SourcePath, $DestinationPath)
        }
    }
    else
    {
        throw "Cannot copy from $SourcePath"
    }
}

# Are We Runing as Admin?
function Test-Admin()
{
    # Get the ID and security principal of the current user account
    $myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
    $myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)

    # Get the security principal for the Administrator role
    $adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator

    # Check to see if we are currently running "as Administrator"
    if ($myWindowsPrincipal.IsInRole($adminRole))
    {
        $global:AdminPriviledges = $true
        return
    }
    else
    {
        #
        # We are not running "as Administrator"
        # Exit from the current, unelevated, process
        #
        throw "You must run this script as administrator"
    }
}

# Are We Running on Nano Server?
function Test-Nano()
{
    $EditionId = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'EditionID').EditionId

    return (($EditionId -eq "NanoServer") -or ($EditionId -eq "ServerTuva"))
}

# Wait For Docker Installation
function Wait-DockerInstallation()
{
    $expiryMinutes = 10
    $startTime = Get-Date
    $timeElapsed = $(Get-Date) - $startTime

    while ($($timeElapsed).TotalMinutes -lt $expiryMinutes)
    {
        if (Test-Docker)
        {
            Write-Output "sleep 20 seconds to let installation finish output"
            Start-Sleep -sec 20
            return;
        }

        Write-Output "Waiting for Docker installation..."
        Start-Sleep -sec 5

        $timeElapsed = $(Get-Date) - $startTime
    }

    throw "Docker did not get installed after $expiryMinutes minutes"
}

# Start Docker
function Start-Docker()
{
    Write-Output "Starting $global:DockerServiceName..."
    if (Test-Nano)
    {
        Start-ScheduledTask -TaskName $global:DockerServiceName
    }
    else
    {
        Start-Service -Name $global:DockerServiceName
    }
}


# Stop Docker
function Stop-Docker()
{
    Write-Output "Stopping $global:DockerServiceName..."
    if (Test-Nano)
    {
        Stop-ScheduledTask -TaskName $global:DockerServiceName

        #
        # ISSUE: can we do this more gently?
        #
        Get-Process $global:DockerServiceName | Stop-Process -Force
    }
    else
    {
        Stop-Service -Name $global:DockerServiceName
    }
}

# Is Docker Installed?
function Test-Docker()
{
    $service = $null

    if (Test-Nano)
    {
        $service = Get-ScheduledTask -TaskName $global:DockerServiceName -ErrorAction SilentlyContinue
    }
    else
    {
        $service = Get-Service -Name $global:DockerServiceName -ErrorAction SilentlyContinue
    }

    return ($service -ne $null)
}

# Wait For Docker To Start
function Wait-Docker()
{
    Write-Output "Waiting for Docker daemon..."
    $dockerReady = $false
    $startTime = Get-Date

    while (-not $dockerReady)
    {
        try
        {
            if (Test-Nano)
            {
                #
                # Nano doesn't support Invoke-RestMethod, we will parse 'docker ps' output
                #
                if ((docker ps 2>&1 | Select-String "error") -ne $null)
                {
                    throw "Docker daemon is not running yet"
                }
            }
            else
            {
                Invoke-RestMethod -Uri http://127.0.0.1:2375/info -Method GET | Out-Null
            }
            $dockerReady = $true
        }
        catch
        {
            $timeElapsed = $(Get-Date) - $startTime

            if ($($timeElapsed).TotalMinutes -ge 1)
            {
                throw "Docker Daemon did not start successfully within 1 minute."
            }

            # Swallow error and try again
            Start-Sleep -sec 1
        }
    }
    Write-Output "Successfully connected to Docker Daemon."
}

try
{
    Wait-DockerInstallation
    Update-ContainerHost
}
catch
{
    Write-Error $_
}
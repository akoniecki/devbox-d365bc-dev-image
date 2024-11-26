@description('Name of the Azure Image Builder resource')
param azureImageBuilderName string = 'devbox-d365bc-imagebuilder'

@description('Azure location for the resources')
param location string = resourceGroup().location

@description('Name of the Azure Compute Gallery')
param galleryName string = 'devbox-d365bc-gallery'

@description('Name of the image definition in the Azure Compute Gallery')
param imageDefName string = 'devbox-d365bc-dev-image'

@description('Name of the resource group used for staging resources during image building.')
param stagingResourceGroupName string = 'imagebuilder-staging'

@description('PowerShell script content for initial setup after Dev Box first startup')
param initialSetupScript string = '''
choco install -y docker-engine
Start-Service docker
Install-Module BcContainerHelper -force
Get-BcContainers
$hostHelperFolder = 'C:\ProgramData\BcContainerHelper'
if (-not (Test-Path $hostHelperFolder)) { New-Item -Path $hostHelperFolder -ItemType Directory }
$acl = Get-Acl -Path $hostHelperFolder
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($env:USERNAME, 'FullControl', 'ContainerInherit, ObjectInherit', 'InheritOnly', 'Allow')
$acl.AddAccessRule($rule)
$hostsFile = "${env:SystemRoot}\System32\drivers\etc\hosts"
Set-Acl -Path $hostHelperFolder -AclObject $acl
$acl = Get-Acl -Path $hostsFile
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($env:USERNAME, 'Modify', 'Allow')
$acl.AddAccessRule($rule)
Set-Acl -Path $hostsFile -AclObject $acl
$npipe = "//./pipe/docker_engine"
$dInfo = New-Object "System.IO.DirectoryInfo" -ArgumentList $npipe                                               
$dSec = $dInfo.GetAccessControl()                                                                                
$fullControl =[System.Security.AccessControl.FileSystemRights]::FullControl                                       
$allow =[System.Security.AccessControl.AccessControlType]::Allow                                                  
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule" -ArgumentList $env:USERNAME, $fullControl, $allow
$dSec.AddAccessRule($rule)                                                                                        
$dInfo.SetAccessControl($dSec)
'''

resource devboxidentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  location: location
  tags: {}
  name: 'imagebuilder-identity'
}

resource azureImageBuilder 'Microsoft.VirtualMachineImages/imageTemplates@2022-02-14' = {
  name: azureImageBuilderName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${devboxidentity.id}': {}
    }
  }
  properties: {
    customize: [
      {
        type: 'PowerShell'
        name: 'Development Environment Setup - AL Language'
        inline: [
          'Set-ExecutionPolicy Bypass -Scope Process -Force'
          '[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072'
          'iex ((New-Object System.Net.WebClient).DownloadString("https://community.chocolatey.org/install.ps1"))'
          'choco install Containers Microsoft-Hyper-V --source windowsfeatures'
          'choco install -y git.install'
          'choco install -y vscode'
          'choco install -y gh'
          'refreshenv'
          '$installerPath = "$env:TEMP\\GitHubDesktopSetup-x64.msi"'
          '(new-object net.webclient).DownloadFile("https://central.github.com/deployments/desktop/desktop/latest/win32?format=msi", $installerPath)'
          'Start-Process msiexec.exe -ArgumentList "/i", $installerPath, "/qn" -NoNewWindow -Wait'
          '$extensions = "ms-dynamics-smb.al","github.vscode-pull-request-github","github.vscode-github-actions","ms-azuretools.vscode-docker","ms-vscode.powershell"'
          'foreach ($ext in $extensions) { code --install-extension $ext }'
        ]
      }
      {
        type: 'PowerShell'
        name: 'Save Initial Setup Script'
        inline: [
          'New-Item -ItemType Directory -Force -Path "C:\\scripts"; $scriptContent = @"\'${initialSetupScript}\'"@; [IO.File]::WriteAllText("C:\\scripts\\initialSetup.ps1", $scriptContent)'
        ]
      }
      {
        type: 'WindowsUpdate'
        searchCriteria: 'IsInstalled=0'
        filters: [
          'exclude:$_.Title -like "*Preview*"'
          'include:$true'
        ]
        updateLimit: 20
      }
      {
        type: 'WindowsRestart'
        restartCommand: 'shutdown /r /f /t 0'
        restartTimeout: '5m'
      }
      {
        type: 'PowerShell'
        name: 'Final Setup Execution'
        inline: [  
          'Set-ItemProperty -Path "HKLM:\\Software\\Microsoft\\Windows\\CurrentVersion\\RunOnce" -Name "initialSetup" -Value "powershell.exe -File C:\\scripts\\initialSetup.ps1"'
        ] 
      }
    ]
    distribute: [{
        type: 'SharedImage'
        galleryImageId: resourceId('Microsoft.Compute/galleries/images', galleryName, imageDefName)
        runOutputName: 'devbox-d365bc-imagebuilder-output'
        replicationRegions: [
          location
        ]
    }]
    source: {
      type: 'PlatformImage'
      publisher: 'MicrosoftVisualStudio'
      offer: 'windowsplustools'
      sku: 'base-win11-gen2'
      version: 'latest'
    }
    vmProfile: {
      vmSize: 'Standard_D16s_v5'
    }
    stagingResourceGroup: resourceId('Microsoft.Resources/resourceGroups', stagingResourceGroupName)
  }
}

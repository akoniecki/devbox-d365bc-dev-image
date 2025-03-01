@description('Name of the Azure Image Builder resource')
param azureImageBuilderName string = 'devbox-d365bc-imagebuilder'

@description('Azure location for the resources (e.g., westeurope, eastus).')
param location string = 'westeurope'

@description('Name of the Azure Compute Gallery.')
param galleryName string = 'devbox-d365bc-gallery'

@description('Name of the image definition in the Azure Compute Gallery.')
param imageDefName string = 'devbox-d365bc-dev-image'

@description('Name of the resource group used for staging resources during image building.')
param stagingResourceGroupName string = 'imagebuilder-staging'

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
        ]
      }
      {
        type: 'PowerShell'
        name: 'Download InitialSetup Script'
        inline: [
          'New-Item -ItemType Directory -Force -Path C:\\scripts'
          'Invoke-WebRequest -Uri "https://raw.githubusercontent.com/akoniecki/devbox-d365bc-dev-image/main/initialSetup.ps1" -OutFile "C:\\scripts\\initialSetup.ps1"'
        ]
      }               
      {
        type: 'WindowsRestart'
        restartCommand: 'shutdown /r /f /t 0'
        restartTimeout: '5m'
      }
      {
        type: 'PowerShell'
        name: 'Initial Setup RunOnce schedule'
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
    stagingResourceGroup: subscriptionResourceId('Microsoft.Resources/resourceGroups', stagingResourceGroupName)
  }
}

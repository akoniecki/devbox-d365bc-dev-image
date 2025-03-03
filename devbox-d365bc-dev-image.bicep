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

@description('Initial setup script URL')
param initialSetupScript string = 'https://raw.githubusercontent.com/akoniecki/devbox-d365bc-dev-image/main/initialSetup.ps1'

@description('Custom script URL (GitHub raw link or Azure storage container with SAS token)')
param customScript string = ''

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
        name: 'D365BC Dev. Environment Setup'
        inline: [
          'New-Item -ItemType Directory -Force -Path C:\\scripts'
          'Invoke-WebRequest -Uri "${initialSetupScript}" -OutFile "C:\\scripts\\initialSetup.ps1"'
          'if (![string]::IsNullOrEmpty("${customScript}")) {'
          '    $customScriptPath = "C:\\scripts\\customSetup.ps1"'
          '    Invoke-WebRequest -Uri "${customScript}" -OutFile $customScriptPath'
          '}'
        ]
      }               
      {
        type: 'WindowsRestart'
        restartCommand: 'shutdown /r /f /t 0'
        restartTimeout: '5m'
      }
      {
        type: 'PowerShell'
        name: 'Setup RunOnce schedules'
        inline: [  
          '$runOnceCmd = "powershell.exe -File C:\\scripts\\initialSetup.ps1"'
          'if (![string]::IsNullOrEmpty("${customScript}")) {'
          '    $customScriptPath = "C:\\scripts\\customSetup.ps1"'
          '    $runOnceCmd += " && powershell.exe -File $customScriptPath"'
          '}'
          'Set-ItemProperty -Path "HKLM:\\Software\\Microsoft\\Windows\\CurrentVersion\\RunOnce" -Name "initialSetup" -Value $runOnceCmd'
        ] 
      }
    ]
    distribute: [{
        type: 'SharedImage'
        galleryImageId: resourceId('Microsoft.Compute/galleries/images', galleryName, imageDefName)
        runOutputName: 'devbox-d365bc-dev-image'
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

resource azureImageBuilder 'Microsoft.VirtualMachineImages/imageTemplates@2022-02-14' = {
  name: azureImageBuilderName
  location: location
  identity:{
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${devboxidentity.id}': {}
    }
  }
  properties:{
    customize: [
      {
        type: 'PowerShell'
        name: 'AL development customisation'
        inline: [
          'Set-ExecutionPolicy Bypass -Scope Process -Force'
          '[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072'
          'iex ((New-Object System.Net.WebClient).DownloadString("https://community.chocolatey.org/install.ps1"))'
          '$ChocolateyProfile = "$env:ChocolateyInstall\\helpers\\chocolateyProfile.psm1"'
          'if (Test-Path($ChocolateyProfile)) { Import-Module $ChocolateyProfile }'
          'choco install Containers Microsoft-Hyper-V --source windowsfeatures'
          'choco install -y git.install'
          'choco install -y vscode'
          'choco install -y gh'
          'refreshenv'
          '$ProgressPreference = "SilentlyContinue"'
          '$installerName = "GitHubDesktopSetup-x64.msi"'
          '$installerPath = Join-Path -Path $env:TEMP -ChildPath $installerName'
          '(new-object net.webclient).DownloadFile("https://central.github.com/deployments/desktop/desktop/latest/win32?format=msi", $installerPath)'
          '$params = "/i", $installerPath, "/qn"'
          '$process = Start-Process "msiexec.exe" -ArgumentList $params -NoNewWindow -Wait -PassThru'
          '$extensions = "ms-dynamics-smb.al","github.vscode-pull-request-github","github.vscode-github-actions","ms-azuretools.vscode-docker","ms-vscode.powershell"'
          '$cmd = "code --list-extensions"'
          'foreach ($ext in $extensions) { code --install-extension $ext }'
          'Copy-Item -Path C:\\Users\\packer\\.vscode\\extensions\\* -Destination "C:\\Program Files\\Microsoft VS Code\\resources\\app\\extensions" -Recurse'
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
    ]
    distribute: [{
        type: 'SharedImage'
        galleryImageId: resourceId('Microsoft.Compute/galleries/images', galleryName, imageDefName)
        runOutputName: 'bc-devbox-generic-sharedimage'
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
    vmProfile:{
      vmSize: 'Standard_D16s_v5'
    }
    stagingResourceGroup: stagingResourceGroupName
  }
}

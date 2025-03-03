choco install -y docker-engine
Start-Service docker
Install-Module BcContainerHelper -force
Check-BcContainerHelperPermissions -Fix -Silent
$extensions = "ms-dynamics-smb.al","github.vscode-pull-request-github","ms-azuretools.vscode-docker","ms-vscode.powershell"
foreach ($ext in $extensions) { code --install-extension $ext }
$genericImage = Get-BestGenericImageName
docker pull $genericImage
choco install -y docker-engine;
Start-Service docker;
Install-Module BcContainerHelper -force;
Get-BcContainers;
$hostHelperFolder = 'C:\\ProgramData\\BcContainerHelper';
if (-not (Test-Path $hostHelperFolder)) { New-Item -Path $hostHelperFolder -ItemType Directory };
$acl = Get-Acl -Path $hostHelperFolder;
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($env:USERNAME, 'FullControl', 'ContainerInherit, ObjectInherit', 'InheritOnly', 'Allow');
$acl.AddAccessRule($rule);
$hostsFile = "$env:SystemRoot\System32\drivers\etc\hosts";
Set-Acl -Path $hostHelperFolder -AclObject $acl;
$acl = Get-Acl -Path $hostsFile;
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($env:USERNAME, 'Modify', 'Allow');
$acl.AddAccessRule($rule);
Set-Acl -Path $hostsFile -AclObject $acl;
$npipe = '//./pipe/docker_engine';
$dInfo = New-Object "System.IO.DirectoryInfo" -ArgumentList $npipe;
$dSec = $dInfo.GetAccessControl();
$fullControl = [System.Security.AccessControl.FileSystemRights]::FullControl;
$allow = [System.Security.AccessControl.AccessControlType]::Allow;
$rule = New-Object "System.Security.AccessControl.FileSystemAccessRule" -ArgumentList $env:USERNAME, $fullControl, $allow;
$dSec.AddAccessRule($rule);
$dInfo.SetAccessControl($dSec);
$extensions = "ms-dynamics-smb.al","github.vscode-pull-request-github","github.vscode-github-actions","ms-azuretools.vscode-docker","ms-vscode.powershell"
foreach ($ext in $extensions) { code --install-extension $ext }

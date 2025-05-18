# create-share.ps1

$sharePath = "C:\Skoletræt"
$shareName = "skoletræt"
$driveLetter = "A"

# Opret mappen hvis den ikke findes
if (-Not (Test-Path -Path $sharePath)) {
    New-Item -ItemType Directory -Path $sharePath | Out-Null
}

# Fjern eksisterende share hvis den findes
if (Get-SmbShare -Name $shareName -ErrorAction SilentlyContinue) {
    Remove-SmbShare -Name $shareName -Force
}

# Del mappen til administratorer
New-SmbShare -Name $shareName -Path $sharePath -FullAccess "Administrators"

# Giv NTFS tilladelser til administrators
$acl = Get-Acl $sharePath
$adminGroup = New-Object System.Security.Principal.NTAccount("Administrators")
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($adminGroup, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.SetAccessRule($accessRule)
Set-Acl -Path $sharePath -AclObject $acl

# Map drev til delingen (bruger variabel)
$networkPath = "\\$env:COMPUTERNAME\$shareName"
New-PSDrive -Name $driveLetter -PSProvider FileSystem -Root $networkPath -Persist -Scope Global
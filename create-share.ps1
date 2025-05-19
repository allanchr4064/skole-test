# setup-shared-drive.ps1

$sharePath = "C:\Skoletræt"
$shareName = "skoletræt"
$driveLetter = "A"
$dcName = "DC01"
$networkPath = "\\$dcName\$shareName"

if ($env:COMPUTERNAME -eq $dcName) {
    Write-Host "==> DC01: Opretter og deler '$sharePath'..."

    # Opret mappe hvis den ikke findes
    if (-Not (Test-Path -Path $sharePath)) {
        New-Item -ItemType Directory -Path $sharePath | Out-Null
    }

    # Giv NTFS-rettigheder til Administrators
    $acl = Get-Acl $sharePath
    $adminGroup = New-Object System.Security.Principal.NTAccount("Administrators")
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $adminGroup, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.SetAccessRule($accessRule)
    $acl.SetOwner($adminGroup)
    Set-Acl -Path $sharePath -AclObject $acl

    # Fjern eksisterende deling hvis den findes
    if (Get-SmbShare -Name $shareName -ErrorAction SilentlyContinue) {
        Remove-SmbShare -Name $shareName -Force
    }

    # Opret ny SMB-deling
    New-SmbShare -Name $shareName -Path $sharePath -FullAccess "Administrators"

    # Genstart SMB server service
    Restart-Service -Name "LanmanServer"
}
else {
    Write-Host "==> Klient: Mapper drev A: til $networkPath"

    # Fjern A: hvis den findes
    if (Get-PSDrive -Name $driveLetter -ErrorAction SilentlyContinue) {
        Remove-PSDrive -Name $driveLetter -Force
    }

    # Vent lidt så DC01 når at dele
    Start-Sleep -Seconds 5

    # Map A: til \\DC01\skoletræt
    try {
        New-PSDrive -Name $driveLetter -PSProvider FileSystem -Root $networkPath -Persist -Scope Global
        Write-Host "==> A: mappet korrekt til $networkPath"
    }
    catch {
        Write-Host "==> FEJL: Kunne ikke mappe A:"
        $_ | Out-File -FilePath C:\Temp\map-error.txt -Encoding utf8
    }
}
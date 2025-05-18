# setup-shared-drive.ps1

$sharePath = "C:\Skoletræt"
$shareName = "skoletræt"
$driveLetter = "A"
$dcName = "DC01"
$networkPath = "\\$dcName\$shareName"

if ($env:COMPUTERNAME -eq $dcName) {
    Write-Host "Denne maskine er DC01 – opretter deling..."

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
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $adminGroup, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.SetAccessRule($accessRule)
    Set-Acl -Path $sharePath -AclObject $acl
}
else {
    Write-Host "Denne maskine er klient – mapper A: til $networkPath"

    # Fjern evt. eksisterende A:
    if (Get-PSDrive -Name $driveLetter -ErrorAction SilentlyContinue) {
        Remove-PSDrive -Name $driveLetter -Force
    }

    # Map A: til \\DC01\skoletræt
    New-PSDrive -Name $driveLetter -PSProvider FileSystem -Root $networkPath -Persist
}
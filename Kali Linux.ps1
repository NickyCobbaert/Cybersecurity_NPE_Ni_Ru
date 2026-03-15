# Naam van user opvragen
$naam = Read-Host "Geef uw user name op (die van uw OS): "

#------------------------------------
# VARIABELEN
#------------------------------------
$VBoxManage = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$vm_naam = "NPE Ni_Ru-Kali Linux"
$memory = "2048"
$os = "Debian_64"
$aantal_cpus = "2"
$videogeheugen = "128"
$naam_vdi = "kali-linux-2025.4-virtualbox-amd64.vdi"

$pad_vdi = Join-Path "C:\Users\$naam\Downloads" $naam_vdi

if ($naam -eq "ruben") {
    $base_folder = "H:\VirtualBox VMs"
} else {
    $base_folder = "C:\VirtualBox VMs"
}

$vm_folder = Join-Path $base_folder $vm_naam

#------------------------------------
# OPRUIMEN
#------------------------------------
& $VBoxManage closemedium disk "$pad_vdi" 2>$null
& $VBoxManage internalcommands sethduuid "$pad_vdi" 2>$null

$bestaandeVMs = & $VBoxManage list vms
if ($bestaandeVMs | Select-String -Pattern "`"$vm_naam`"") {
    & $VBoxManage controlvm $vm_naam poweroff 2>$null
    & $VBoxManage unregistervm $vm_naam --delete
    Start-Sleep -Seconds 2
}

if (Test-Path $vm_folder) {
    Remove-Item -Path $vm_folder -Recurse -Force
}

#------------------------------------
# VM AANMAKEN
#------------------------------------
& $VBoxManage createvm --name $vm_naam --ostype $os --register --basefolder $base_folder

#------------------------------------
# BASISCONFIGURATIE
#------------------------------------
& $VBoxManage modifyvm $vm_naam --memory $memory
& $VBoxManage modifyvm $vm_naam --cpus $aantal_cpus
& $VBoxManage modifyvm $vm_naam --vram $videogeheugen

#------------------------------------
# STORAGE
#------------------------------------
& $VBoxManage storagectl $vm_naam --name "SATA" --add sata --controller IntelAhci
& $VBoxManage storageattach $vm_naam --storagectl "SATA" --port 0 --device 0 --type hdd --medium "$pad_vdi"

#------------------------------------
# STARTEN
#------------------------------------
& $VBoxManage startvm $vm_naam

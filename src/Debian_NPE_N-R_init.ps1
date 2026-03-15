
$naam = Read-Host "Geef uw user name op: "

#---------------------------
# Variables
#---------------------------

if ( $IsLinux ){
    $VBoxManage = "/usr/bin/vboxmanage"
} elseif ( $IsWindows ) {
    $VBoxManage = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
} else{
    Write-Host -ForegroundColor Red "Critical Error: Your Operating System is currently not supported!"
    exit 1
}


$VMName = "NPE_Ni_Ru_Debian_Apache_2.4.49"
$memory = "4096"
$os = "Debian_64"
$CPUs = "2"
$VRAM = "128"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$VDIFolder = Join-Path -Path $ScriptDir -ChildPath "VDI-folder"
$NAME_VDI = Get-ChildItem -Path "$VDIFolder" -Filter  "*Debian*" -name

$VDI_PATH = Join-Path -Path $VDIFolder -ChildPath "$NAME_VDI"
$MAIN_VM_FOLDER = "C:\VirtualBox VMs"

if ($naam -eq "ruben") {
    $MAIN_VM_FOLDER = "H:\VirtualBox VMs"
}elseif ($IsLinux) {
    $MAIN_VM_FOLDER = "$($HOME)/VirtualBox VMs"
} 

$VM_FOLDER = Join-Path -Path "$MAIN_VM_FOLDER" -ChildPath "$VMName"

$PROVISIONING_PATH = Join-Path -Path "$ScriptDir" -ChildPath "Provisioning"


#------------------------------------
# CLEANUP
#------------------------------------
& $VBoxManage closemedium disk "$VDI_PATH" 2>$null
& $VBoxManage internalcommands sethduuid "$VDI_PATH" 2>$null

$EXISTINGVMS = & $VBoxManage list vms
if ($EXISTINGVMS | Select-String -Pattern "`"$VMName`"") {
    & $VBoxManage controlvm $VMName poweroff 2>$null
    & $VBoxManage unregistervm $VMName --delete
}

if (Test-Path $vm_folder) {
    Remove-Item -Path $vm_folder -Recurse -Force
}


#------------------------------------
# VM CREATION
#------------------------------------
& $VBoxManage createvm --name $VMName --ostype $os --register --basefolder $MAIN_VM_FOLDER

#------------------------------------
# HARDWARE CONFIGURATION
#------------------------------------
& $VBoxManage modifyvm $VMName --memory $memory --cpus $CPUs --vram $VRAM

#------------------------------------
# STORAGE
#------------------------------------
& $VBoxManage storagectl $VMName --name "SATA" --add sata --controller IntelAhci
& $VBoxManage storageattach $VMName --storagectl "SATA" --port 0 --device 0 --type hdd --medium "$VDI_PATH"

& $VBoxManage sharedfolder add $VMName --name="Deb_NPE_N-R" --hostpath="$PROVISIONING_PATH" --automount --auto-mount-point="/Deb_NPE_N-R"

#------------------------------------
# STARTUP
#------------------------------------

& $VBoxManage startvm $VMName

#------------------------------------
# PROVISION
#------------------------------------

& $VBoxManage guestcontrol $VMName run --exe "/bin/bash" -- "/Deb_NPE_N-R/Debian_Apache_2.4.49_Provisioner.sh"



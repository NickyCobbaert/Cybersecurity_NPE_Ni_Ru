# Naam van user opvragen
$naam = Read-Host "Geef uw user name op (die van uw OS)"

#------------------------------------
# VARIABELEN
#------------------------------------

if ( $IsLinux ) {
    $VBoxManage = "/usr/bin/vboxmanage"
} elseif ( $IsWindows ) {
    $VBoxManage = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
} else {
    Write-Host -ForegroundColor Red "Critical Error: Your Operating System is currently not supported!"
    exit 1
}

$VMName = "NPE Ni_Ru-Kali Linux"
$memory = "4096"
$os = "Debian_64"
$CPUs = "2"
$VRAM = "128"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$VDIFolder = Join-Path -Path $ScriptDir -ChildPath "VDI-folder"
$NAME_VDI = Get-ChildItem -Path "$VDIFolder" -Filter "*kali*.vdi" -Name

$VDI_PATH = Join-Path -Path $VDIFolder -ChildPath "$NAME_VDI"

$MAIN_VM_FOLDER = "C:\VirtualBox VMs"

if ($naam -eq "ruben") {
    $MAIN_VM_FOLDER = "H:\VirtualBox VMs"
} elseif ($IsLinux) {
    $MAIN_VM_FOLDER = "$($HOME)/VirtualBox VMs"
}

$VM_FOLDER = Join-Path -Path "$MAIN_VM_FOLDER" -ChildPath "$VMName"


function Cleanup {

    #------------------------------------
    # CLEANUP
    #------------------------------------

    do {
        $CLEAN = Read-Host "Do you want to delete the VM and it's files? (y = yes, n = no)"
    } while (($CLEAN -ne 'n' -and $CLEAN -ne 'y'))

    if ( $CLEAN -eq 'y') {

        & $VBoxManage closemedium disk "$VDI_PATH" 2>$null
        & $VBoxManage internalcommands sethduuid "$VDI_PATH" 2>$null

        $EXISTINGVMS = & $VBoxManage list vms
        if ($EXISTINGVMS | Select-String -Pattern "`"$VMName`"") {
            & $VBoxManage controlvm $VMName poweroff 2>$null
            & $VBoxManage unregistervm $VMName --delete
        }

        if (Test-Path $VM_FOLDER) {
            Remove-Item -Path $VM_FOLDER -Recurse -Force
        }

    }

}


function Creation {

    #------------------------------------
    # VM AANMAKEN
    #------------------------------------
    & $VBoxManage createvm --name $VMName --ostype $os --register --basefolder $MAIN_VM_FOLDER

    #------------------------------------
    # HARDWARE CONFIGURATION
    #------------------------------------
    & $VBoxManage modifyvm $VMName --memory $memory --cpus $CPUs --vram $VRAM
    & $VBoxManage modifyvm $VMName --natpf1 "guestssh,tcp,,2222,,22"  --nic2 hostonly --hostonlyadapter2 "VirtualBox Host-Only Ethernet Adapter #2"

    #------------------------------------
    # STORAGE
    #------------------------------------
    # Eerst VDI loskoppelen uit registry en nieuw UUID geven om conflicten te vermijden
    & $VBoxManage closemedium disk "$VDI_PATH" 2>$null
    & $VBoxManage internalcommands sethduuid "$VDI_PATH"

    & $VBoxManage storagectl $VMName --name "SATA" --add sata --controller IntelAhci
    & $VBoxManage storageattach $VMName --storagectl "SATA" --port 0 --device 0 --type hdd --medium "$VDI_PATH"

}


#------------------------------------
# VM VALIDATION
#------------------------------------

if (& $VBoxManage list vms | Where-Object { $_ -match [regex]::Escape($VMName) }) {

    Write-Host -BackgroundColor DarkCyan "Info: The VM does already exist!"

    #------------------------------------
    # CLEANUP
    #------------------------------------

    Cleanup

    do {
        $RECREATION = Read-Host "Do you want a new iteration of the VM? (y = yes ; n = no)"
    } while (($RECREATION -ne 'n' -and $RECREATION -ne 'y'))

    if ( $RECREATION -eq 'y' ) {
        #------------------------------------
        # CREATION
        #------------------------------------
        Creation
    }

} else {

    #------------------------------------
    # CREATION
    #------------------------------------
    Creation

}

#------------------------------------
# STARTEN
#------------------------------------
& $VBoxManage startvm $VMName


#------------------------------------
# CLEANUP
#------------------------------------

Cleanup

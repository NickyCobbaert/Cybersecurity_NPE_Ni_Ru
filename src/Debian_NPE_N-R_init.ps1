
$naam = Read-Host "Geef uw user name op"

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
$NAME_VDI = Get-ChildItem -Path "$VDIFolder" -Filter  "*Debian*.vdi" -name

$VDI_PATH = Join-Path -Path $VDIFolder -ChildPath "$NAME_VDI"
$MAIN_VM_FOLDER = "C:\VirtualBox VMs"

if ($naam -eq "ruben") {
    $MAIN_VM_FOLDER = "H:\VirtualBox VMs"
}elseif ($IsLinux) {
    $MAIN_VM_FOLDER = "$($HOME)/VirtualBox VMs"
} 

$VM_FOLDER = Join-Path -Path "$MAIN_VM_FOLDER" -ChildPath "$VMName"

$PROVISIONING_PATH = Join-Path -Path "$ScriptDir" -ChildPath "Provisioning"
$PROVISIONING_FILE = Join-Path -Path "$PROVISIONING_PATH" -ChildPath "Debian_Apache_2.4.49_Provisioner.sh"

function Cleanup{

    #------------------------------------
    # CLEANUP
    #------------------------------------
    
    do{
        $CLEAN = Read-Host "Do you want to delete the VM and it's files? (y = yes, n = no)"
    }while ( ($CLEAN -ne 'n' -and $CLEAN -ne 'y'))
    
    if ( $CLEAN -eq 'y'){
        
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
    
    }

}


function Creation{

    #------------------------------------
    # VM CREATION
    #------------------------------------

    & $VBoxManage createvm --name $VMName --ostype $os --register --basefolder $MAIN_VM_FOLDER
    
    #------------------------------------
    # HARDWARE CONFIGURATION
    #------------------------------------
    & $VBoxManage modifyvm $VMName --memory $memory --cpus $CPUs --vram $VRAM
    & $VBoxManage modifyvm $VMName --natpf1 "guestssh,tcp,,2222,,22"
    
    #------------------------------------
    # STORAGE
    #------------------------------------
    & $VBoxManage storagectl $VMName --name "SATA" --add sata --controller IntelAhci
    & $VBoxManage storageattach $VMName --storagectl "SATA" --port 0 --device 0 --type hdd --medium "$VDI_PATH"

}


#------------------------------------
# VM VALIDATION
#------------------------------------

if (& $VBoxManage list  vms | Where-Object { $_ -match [regex]::Escape($VMName) } ) {

    Write-Host -BackgroundColor DarkCyan "Info: The VM does already exist!"

    #------------------------------------
    # CLEANUP
    #------------------------------------
    
    Cleanup

    do{

    $RECREATION = Read-Host "Do you want a new iteration of the VM? (y = yes ; n = no)"

    }while ( ($RECREATION -ne 'n' -and $RECREATION -ne 'y'))

    if ( $RECREATION -eq 'y' ){

        #------------------------------------
        # CREATION
        #------------------------------------

        Creation
    }


}else{

    #------------------------------------
    # CREATION
    #------------------------------------

    Creation

}


#------------------------------------
# STARTUP
#------------------------------------

& $VBoxManage startvm $VMName 2>$null

#------------------------------------
# PROVISION
#------------------------------------

#provision file:
#read content (whole file, not lines (raw)) -> Change to Linux line endings -> ssh run bash ->  give everything to bash with ssh
Get-Content "$PROVISIONING_FILE" -Raw | ForEach-Object { $_ -replace "`r`n", "`n" } | ssh debian@localhost -o StrictHostKeyChecking=no -p 2222 "bash"


#------------------------------------
# CLEANUP
#------------------------------------

Cleanup

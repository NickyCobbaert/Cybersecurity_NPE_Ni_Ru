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


$VMName = "NPE_Ni_Ru_CWP_Rocky_8"
$memory = "2048"
$os = "RedHat_64"
$CPUs = "2"
$VRAM = "128"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$VDIFolder = Join-Path -Path $ScriptDir -ChildPath "VDI-folder"
$NAME_VDI = Get-ChildItem -Path "$VDIFolder" -Filter "*Rocky*.vdi" -name

$VDI_PATH = Join-Path -Path $VDIFolder -ChildPath "$NAME_VDI"
$MAIN_VM_FOLDER = "C:\VirtualBox VMs"

if ($IsLinux) {
    $MAIN_VM_FOLDER = "$($HOME)/VirtualBox VMs"
} 

$VM_FOLDER = Join-Path -Path "$MAIN_VM_FOLDER" -ChildPath "$VMName"

$PROVISIONING_PATH = Join-Path -Path "$ScriptDir" -ChildPath "Provisioning"
$PROVISIONING_FILE = Join-Path -Path "$PROVISIONING_PATH" -ChildPath "CWP.sh"

function Creation{

    #------------------------------------
    # VM CREATION
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
    & $VBoxManage storagectl $VMName --name "SATA" --add sata --controller IntelAhci
    & $VBoxManage storageattach $VMName --storagectl "SATA" --port 0 --device 0 --type hdd --medium "$VDI_PATH"
}


#------------------------------------
# VM VALIDATION
#------------------------------------

if (& $VBoxManage list  vms | Where-Object { $_ -match [regex]::Escape($VMName) } ) {

    Write-Host -BackgroundColor DarkCyan "Info: The VM does already exist!"

   
    do{
    $RECREATION = Read-Host "Do you want a new iteration of the VM? (y = yes ; n = no)"
    }while ( ($RECREATION -ne 'n' -and $RECREATION -ne 'y'))

    if ( $RECREATION -eq 'y' ){
        Creation
    }
}else{
    Creation
}


#------------------------------------
# STARTUP
#------------------------------------

& $VBoxManage startvm $VMName 2>$null
Write-Host "VM gestart. Wacht tot SSH beschikbaar is!" -ForegroundColor Yellow
Write-Host "Als de vm is opgestart, klik dan enter!"  -ForegroundColor Yellow

Read-Host -Prompt "Press Enter to continue"

#------------------------------------
# PROVISION
#------------------------------------

if (-not (Test-Path $PROVISIONING_FILE)) {
    Write-Host "Provisioning file niet gevonden: $PROVISIONING_FILE" -ForegroundColor Red
    exit 1
}
#provision file:
#read content (whole file, not lines (raw)) -> Change to Linux line endings -> ssh run bash ->  give everything to bash with ssh
Get-Content "$PROVISIONING_FILE" -Raw | ForEach-Object { $_ -replace "`r`n", "`n" } | ssh rockylinux@localhost -o StrictHostKeyChecking=no -p 2222 "bash"


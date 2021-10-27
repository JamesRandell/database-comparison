# Checks for the existance of VMs in Hyper-V and creates them if they don't exist

# there are two ways to run this script:
# ISO: You're starting fresh and have a bootable ISO to mount as a virtual DVD drive and 'install' the guest OS
# VHDX: You've already done that bit, and you have a virtual HD to use and copy around to VMs. This VHDX will usually be a freshly installed guest OS
$buildFromISO = 0;


# settings
$vmBaseImage = "C:\Users\Public\Documents\Hyper-V\VM images\CentOS-fresh.vhdx"
$vmName = "CentOS" # name of VM, this just applies in Windows, it isn't applied to the OS guest itself.
$image = "C:\Users\Public\Documents\Hyper-V\VM images\CentOS-Stream-8-x86_64-20210506-boot.iso"
$vmswitch = "lab" # name of your local vswitch
$port = "Network Adapter" # port on the VM
$cpu =  2 # Number of CPUs
$ram = 4GB # RAM of VM. Note this is not a string, not in quotation marks
$pathToDisk = "C:\Users\Public\Documents\Hyper-V\Virtual hard disks\" # Where you want the VM's virtual disk to reside
$disk_size = 20GB # VM storage, again, not a string

$replaceVM = 1
$startVM = 1

# how many Vms to build
$numberOfVM = 5






function checkForVM {

    [CmdletBinding()]
	param(
		[Parameter()]
		[string] $vmName
	)

    $Exists = get-vm -name $vmName -ErrorAction SilentlyContinue
    If ($Exists){
        return 1
    }
    
    return 0
}

function buildVM {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string] $vmName
    )

    
    
    New-VM $vmName
    Set-VM $vmName -ProcessorCount $cpu -MemoryStartupBytes $ram -MemoryMaximumBytes $ram

    # are we using an ISO to boot, or a base image VHDX to mount?
    If ($buildFromISO -eq 1) {
        New-VHD -Path "$path_to_disk$vmName-disk1.vhdx" -SizeBytes $disk_size
        Set-VMDvdDrive -VMName $vmName -Path "$image"
    } else {
        Copy-Item "$vmBaseImage" -Destination "$pathToDisk$vmName-disk1.vhdx"
    }
    
    
    Add-VMHardDiskDrive -VMName $vmName -Path "$pathToDisk$vmName-disk1.vhdx"
    Remove-VMNetworkAdapter -VMName $vmName
    Add-VMNetworkAdapter -VMName $vmName -Name $port
    #Set-VMNetworkAdapterVlan -VMName $vmName -VMNetworkAdapterName $port -Access -AccessVlanId $vlan
    Connect-VMNetworkAdapter -VMName $vmName -Name $port -SwitchName $vmswitch
    
    
    
}

function startVM {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string] $vmName
    )

    Start-VM $vmName 
    Write-Output $vmName
}

function removeVM {

    [CmdletBinding()]
    param(
        [Parameter()]
        [string] $vmName
    )
    Write-Output "Deleting old VM: '$vmName'"
    Stop-VM -Name $vmName -TurnOff:$true -Confirm:$false
    Get-VM -Name $vmName | Get-VMHardDiskDrive | Foreach-Object { 
        Remove-item -path $_.Path
        Write-Output  "Deleting vhdx file: $_.Path"
    }

    Remove-VM -Name $vmName -Force
    Write-Output "VM: '$vmname' removed"
}







For ($i = 1; $i -le $numberOfVM; $i++) {

    $vmNameTemp = $vmname + " " + $i;

    $temp = checkForVM($vmNameTemp);
    If ($temp -eq 0) {
        buildVM($vmNameTemp);
        
    } else {
        if ($replaceVM -eq 1) {
            removeVM($vmNameTemp);
            buildVM($vmNameTemp);
        }
    }

    If ($startVM -eq 1) {
        startVM($vmNameTemp);
    }
}
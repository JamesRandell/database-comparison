Set-Content -Path "C:\Users\james\Code\Database Comparison\ansible\inventory\inventory.yml" -Value "[servers]"

$output = get-vm | 
Where-Object {$_.Name -like "CentOS*"} | 
Select-Object -ExpandProperty Networkadapters | 
Select-Object @{
    label='Servers';
    expression={'"' + ($_.VMName.ToString()) + '"'}
}, @{ 
    label=' ';
    expression={"ansible_host=" + ($_.IPAddresses).split(',')[0] + " ansible_ssh_extra_args='-o StrictHostKeyChecking=no' ansible_user=root ansible_password=james"}
} | 
Format-Table -HideTableHeaders
$t = Out-String -InputObject $output -Width 200
Add-Content -Path "C:\Users\james\Code\Database Comparison\ansible\inventory\inventory.yml" -Value $t
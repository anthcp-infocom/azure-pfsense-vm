Connect-AzAccount
$ResourceGroupName = "fw1_group"
$pfresourcegroup = "fw1_group"
$StorageAccountName = "ozystore"
$vnetpubname = "pf-pub-vnet"
$vnetintname = "pf-int-vnet"
$NSGname = "******"
$location = "Australia East"
$locationName = "australiaeast"

Remove-AzResourceGroup -Name $ResourceGroupName
New-AzResourceGroup -Name $ResourceGroupName -Location $location
# public vnet
$vnetPubDict = @{
    Name = $vnetpubname
    ResourceGroupName = $ResourceGroupName
    Location = $location
    AddressPrefix = '10.0.0.0/16'
}
$newvnetpub = New-AzVirtualNetwork @vnetPubDict
$vnetpub = Get-AzVirtualNetwork -Name $vnetpubname -ResourceGroupName $ResourceGroupName
# add default subnet
$subnetpub = @{
    Name = 'default'
    VirtualNetwork = $vnetpub
    AddressPrefix = '10.0.64.0/24'
}
$pubSubnet = Add-AzVirtualNetworkSubnetConfig @subnetpub
$vnetpub | Set-AzVirtualNetwork
$vnetpub = Get-AzVirtualNetwork -Name $vnetpubname -ResourceGroupName $ResourceGroupName
# internal vnet
$vnetIntDict = @{
    Name = $vnetintname
    ResourceGroupName = $ResourceGroupName
    Location = $location
    AddressPrefix = '172.16.0.0/16'
}
$newvnetint = New-AzVirtualNetwork @vnetIntDict
$vnetint = Get-AzVirtualNetwork -Name $vnetintname -ResourceGroupName $ResourceGroupName
# add default subnet
$subnetint = @{
    Name = 'default'
    VirtualNetwork = $vnetint
    AddressPrefix = '172.16.0.0/24'
}
$pubSubnet = Add-AzVirtualNetworkSubnetConfig @subnetint
$vnetint | Set-AzVirtualNetwork
$vnetint = Get-AzVirtualNetwork -Name $vnetintname -ResourceGroupName $ResourceGroupName
# $subnet = @{
#     Name = 'default'
#     VirtualNetwork = $vnet
#     AddressPrefix = '10.0.64.0/24'
# }
# $backendSubnet = Add-AzVirtualNetworkSubnetConfig @subnet
# $vnet | Set-AzVirtualNetwork
#$backendSubnet = Get-AzVirtualNetworkSubnetConfig -Name default -VirtualNetwork $vnet
$vmName="pfsense"
$vmSize="Standard_B1s"
$pubip = New-AzPublicIpAddress -Name "PFPubIP" -ResourceGroupName $pfresourcegroup -Location $location -AllocationMethod Dynamic
$nic1 = New-AzNetworkInterface -Name "EXPFN1NIC1" -ResourceGroupName $pfresourcegroup -Location $location -SubnetId $vnetpub.Subnets[0].Id -PublicIpAddressId $pubip.Id
$nic2 = New-AzNetworkInterface -Name "EXPFN1NIC2" -ResourceGroupName $pfresourcegroup -Location $location -SubnetId $vnetint.Subnets[0].Id
$VM = New-AzVMConfig -VMName $vmName -VMSize $vmSize
[Console]::ReadKey()
Set-AzVMOSDisk -VM $VM -VhdUri "https://ozystore.blob.core.windows.net/vhds/pffwhd.vhd" -Name "pfsenseos" -CreateOption Attach -Linux -Caching ReadWrite
$vm = Add-AzVMNetworkInterface -VM $vm -Id $nic1.Id
$vm = Add-AzVMNetworkInterface -VM $vm -Id $nic2.Id
$vm.NetworkProfile.NetworkInterfaces.Item(0).Primary = $true
New-AzVM -ResourceGroupName $pfresourcegroup -Location $locationName -VM $vm -Verbose
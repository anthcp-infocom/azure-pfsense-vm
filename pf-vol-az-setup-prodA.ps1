Connect-AzAccount
$ResourceGroupName = "fw1_group"
$pfresourcegroup = "fw1_group"
$StorageAccountName = "ozystore"
$vnetname = "pf-vnet"
$NSGname = "******"
$location = "Australia East"
$locationName = "australiaeast"

Remove-AzResourceGroup -Name $ResourceGroupName
New-AzResourceGroup -Name $ResourceGroupName -Location $location
# vnet
$vnetDict = @{
    Name = $vnetname
    ResourceGroupName = $ResourceGroupName
    Location = $location
    AddressPrefix = '10.0.0.0/16'
}
$newvnet = New-AzVirtualNetwork @vnetDict
$vnet = Get-AzVirtualNetwork -Name $vnetname -ResourceGroupName $ResourceGroupName
# add default subnet
$subnetdef = @{
    Name = 'default'
    VirtualNetwork = $vnet
    AddressPrefix = '10.0.64.0/24'
}
$defSubnet = Add-AzVirtualNetworkSubnetConfig @subnetdef
$vnet | Set-AzVirtualNetwork
$vnet = Get-AzVirtualNetwork -Name $vnetname -ResourceGroupName $ResourceGroupName
# add pub subnet
$subnetpub = @{
    Name = 'hot'
    VirtualNetwork = $vnet
    AddressPrefix = '10.0.128.0/24'
}
$pubSubnet = Add-AzVirtualNetworkSubnetConfig @subnetpub
$vnet | Set-AzVirtualNetwork
$vnet = Get-AzVirtualNetwork -Name $vnetname -ResourceGroupName $ResourceGroupName
$defSubnet = Get-AzVirtualNetworkSubnetConfig -Name default -VirtualNetwork $vnet
$hotSubnet = Get-AzVirtualNetworkSubnetConfig -Name hot -VirtualNetwork $vnet
# setup VM
$vmName="pfsense"
$vmSize="Standard_B1s"
$pubip = New-AzPublicIpAddress -Name "PFPubIP" -ResourceGroupName $pfresourcegroup -Location $location -AllocationMethod Dynamic
$nic1 = New-AzNetworkInterface -Name "EXPFN1NIC1" -ResourceGroupName $pfresourcegroup -Location $location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pubip.Id
$nic2 = New-AzNetworkInterface -Name "EXPFN1NIC2" -ResourceGroupName $pfresourcegroup -Location $location -SubnetId $vnet.Subnets[1].Id
$VM = New-AzVMConfig -VMName $vmName -VMSize $vmSize
Set-AzVMOSDisk -VM $VM -VhdUri "https://ozystore.blob.core.windows.net/vhds/pffwhd.vhd" -Name "pfsenseos" -CreateOption Attach -Linux -Caching ReadWrite
$vm = Add-AzVMNetworkInterface -VM $vm -Id $nic1.Id
$vm = Add-AzVMNetworkInterface -VM $vm -Id $nic2.Id
$vm.NetworkProfile.NetworkInterfaces.Item(0).Primary = $true
New-AzVM -ResourceGroupName $pfresourcegroup -Location $locationName -VM $vm -Verbose
<#
    .DESCRIPTION
        A runbook which gets all the Subnets, total IP addresses available and remaining IP addresses in each Subnet.

    .NOTES
        AUTHOR: Ishan SHukla
        LASTEDIT: Jan 23, 2023
#>

"Please enable appropriate RBAC permissions to the system identity of this automation account. Otherwise, the runbook may fail..."

try
{
    "Logging in to Azure..."
    Connect-AzAccount -Identity
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

$vnetdet = @()

$ResourceDetails = Get-AzResource #-ResourceGroupName $ResourceGroupName

$getvnet =  $ResourceDetails | Where-Object {$_.resourcetype -eq "Microsoft.Network/virtualNetworks"} | Get-AzVirtualNetwork 

$subusage1  = $getvnet | foreach-Object {Get-AzVirtualNetworkUsageList -Name $_.Name -ResourceGroupName $_.ResourceGroupName }

for ($v=0; $v -lt $getvnet.count; $v++){
$getsubnet = $getvnet[$v] | Get-AzVirtualNetworkSubnetConfig 

for ($s=0; $s -lt $getsubnet.count; $s++){
    $subusage  = $subusage1 | Where-Object {$_.Id -eq $getsubnet[$s].id}

        $subnethash = [ordered]@{
            'VNET#'            = $v+1
            VNETName           = $getvnet[$v].Name
            VNETPrefix         = $($getvnet[$v].AddressSpace.AddressPrefixes -replace "{" -replace "}")
            'Subnet#'          = $s+1
            SubnetsName        = $getsubnet[$s].name
            SubnetPrefix       = $($getsubnet[$s].AddressPrefix  -replace "{" -replace "}")
            SubnetIPsUsed      = $subusage.CurrentValue
            SubnetIPAvailable  = $subusage.Limit - $subusage.CurrentValue
            ResourceGroupName  = $getvnet[$v].ResourceGroupName
            SubscriptionName   = (Get-AzContext).Subscription.Name
    

        }
        # VNET and Subnet details in a Resource Group.
        $vnetdet += New-Object PSObject  -Property $subnethash
}
}
#$vnetdet


#$alert = $vnetdet |  Where-Object {$_.SubnetIPAvailable -lt '5'} 
  
Write-Output ("Showing available IPs ")

$vnetdet

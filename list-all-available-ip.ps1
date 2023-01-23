<#
    .DESCRIPTION
        A runbook which gets all the Subnets, total IP addresses available and remaining IP addresses in each Subnet.

    .NOTES
        AUTHOR: Ishan Shukla
        LASTEDIT: Jan 23, 2023

    .PARAMETER Subid
    Subscription ID for which the Subnets will be queried. Optional, if not provided, default Subscription will be selected. 

    .PARAMETER Lessthan
    Number for which you want to check the available IP addresses. 
#>

Param(
    [Parameter(Mandatory=$false)]
    [String]$Subid,
    [Parameter(Mandatory=$false)]
    [Int]$Lessthan
)

"Please enable appropriate RBAC permissions to the system identity of this automation account. Otherwise, the runbook may fail..."

try
{
    "Logging in to Azure..."
    Connect-AzAccount -Identity
    start-sleep -seconds 30
    if($Subid -eq $null){
       $Subid =  (Get-AzContext).Subscription.id 
       Select-AzSubscription -SubscriptionId $Subid 
    }

    
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

$vnetdet = @()

$getvnet =  Get-AzVirtualNetwork 

$subusage1 = $getvnet | foreach-Object {Get-AzVirtualNetworkUsageList -Name $_.Name -ResourceGroupName $_.ResourceGroupName }

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
            PercentAvailable   = (($(($subusage.Limit - $subusage.CurrentValue)/$($subusage.Limit))*100))
            ResourceGroupName  = $getvnet[$v].ResourceGroupName
            SubscriptionName   = (Get-AzContext).Subscription.Name
    

        }
        # VNET and Subnet details.
        $vnetdet += New-Object PSObject  -Property $subnethash
}
}
#$vnetdet


#$alert = $vnetdet |  Where-Object {$_.SubnetIPAvailable -lt '5'} 
  
Write-Host "Showing available IPs " -ForegroundColor Green

$vnetdet 

If(!($Lessthan)){
$alert = $vnetdet |  Where-Object {$_.PercentAvailable -lt '50'} 

Write-Host  "Showing Subnets with less than 50% available IPs " -ForegroundColor Yellow

$alert
}

Else{
$alert = $vnetdet |  Where-Object {$_.PercentAvailable -lt $Lessthan} 

Write-Host  "Showing Subnets with less than $($Lessthan)% available IPs " -ForegroundColor Yellow

$alert
}



function RemoveEmptyZones {
    Param(
        [Parameter(Mandatory = $False, Position = 2, HelpMessage = "Pass array as System.Collections.ArrayList object")]
        [string[]]
        $AzurePublicDnsZoneForwarders
    )

    $NoEmptiesAllAzurePublicDnsZoneForwarders = $AzurePublicDnsZoneForwarders.Split('', [System.StringSplitOptions]::RemoveEmptyEntries)
    Return $NoEmptiesAllAzurePublicDnsZoneForwarders
}

function CreateRegionZones {
    Param(
        [Parameter(Mandatory = $False, Position = 2, HelpMessage = "Pass array as System.Collections.ArrayList object")]
        [System.Collections.ArrayList]
        $AzurePublicDnsZoneForwarders,
        [Parameter(Mandatory = $False, Position = 2, HelpMessage = "Enter the Azure regions for which you want to create respecive conditional forwarders.")]
        [string[]]
        $HARegions
    )

    [System.Collections.ArrayList]$AllAzurePublicDnsZoneForwardersWithRegions = $AzurePublicDnsZoneForwarders.Clone()
    ForEach ($Zone in $AzurePublicDnsZoneForwarders) {
        #Check if the zone has {region} in it, if so swap out for the place holder for the regions specified
        If ('{region}' -eq $Zone.Substring(0, $Zone.IndexOf("."))) {
            [void]$AllAzurePublicDnsZoneForwardersWithRegions.Remove($Zone)
            If ($Null -ne $HARegions) {
                Foreach ($Region in $HARegions) {
                    $ZoneRegion = $Zone.Replace('{region}', $Region)
                    [void]$AllAzurePublicDnsZoneForwardersWithRegions.Add($ZoneRegion)
                }
            }
        }
    }
    Return $AllAzurePublicDnsZoneForwardersWithRegions
}

function CreatePartitionZones {
    Param(
        [Parameter(Mandatory = $False, Position = 2, HelpMessage = "Pass array as System.Collections.ArrayList object")]
        [System.Collections.ArrayList]
        $AzurePublicDnsZoneForwarders,
        [Parameter(Mandatory = $false, Position = 3, HelpMessage = "Enter the partition IDs of any static web apps, if applicable, for which you want to create respecive conditional forwarders.")]
        [string[]]
        $PartitionIDs
    )

    [System.Collections.ArrayList]$AllAzurePublicDnsZoneForwardersWithRegionsAndPartitions = $AzurePublicDnsZoneForwarders.Clone()
    ForEach ($Zone in $AzurePublicDnsZoneForwarders) {
        #Check if the zone has {region} in it, if so swap out for the place holder for the regions specified
        If ('{partitionId}' -eq $Zone.Substring(0, $Zone.IndexOf("."))) {
            [void]$AllAzurePublicDnsZoneForwardersWithRegionsAndPartitions.Remove($Zone)
            If ($Null -ne $PartitionIDs) {
                Foreach ($ID in $PartitionIDs) {
                    $ZonePartition = $Zone.Replace('{partitionId}', $ID)
                    [void]$AllAzurePublicDnsZoneForwardersWithRegionsAndPartitions.Add($ZonePartition)
                }
            }
        }
    }

    Return $AllAzurePublicDnsZoneForwardersWithRegionsAndPartitions
}

function CreateSqlInstances {
    Param(
        [Parameter(Mandatory = $False, Position = 2, HelpMessage = "Pass array as System.Collections.ArrayList object")]
        [System.Collections.ArrayList]
        $AzurePublicDnsZoneForwarders,
        [Parameter(Mandatory = $false, Position = 3, HelpMessage = " ArrayList to enter the SQL instances & DB in '{instance}.{db),'{instance2}.{db)' format if applicable, for which you want to create respecive conditional forwarders.")]
        [string[]]
        $InstanceDotDB
    )
    [System.Collections.ArrayList]$NoEmptiesWithRegionsWithPartitionsSqlInstancesAllAzurePublicDnsZoneForwarders = $AzurePublicDnsZoneForwarders.Clone()
    ForEach ($Zone in $AzurePublicDnsZoneForwarders) {

        If (($Zone.Split('.')).Count -gt 3) {

            if ('{instanceName}.{dnsPrefix}' -eq $Zone.Substring(0, $Zone.IndexOf(".", $Zone.IndexOf(".") + 1))) {

                [void]$NoEmptiesWithRegionsWithPartitionsSqlInstancesAllAzurePublicDnsZoneForwarders.Remove($Zone)
                If ($Null -ne $InstanceDotDB) {
                    Foreach ($Instance in $InstanceDotDB ) {
                        $ZoneSqlInstance = $Zone.Replace('{instanceName}.{dnsPrefix}', $Instance)
                        [void]$NoEmptiesWithRegionsWithPartitionsSqlInstancesAllAzurePublicDnsZoneForwarders.Add($ZoneSqlInstance)
                    }
                }
            }
        }
    }
    Return $NoEmptiesWithRegionsWithPartitionsSqlInstancesAllAzurePublicDnsZoneForwarders
}

Function RemoveConditionalForwarders {
    Param(
        [Parameter(Mandatory = $False, Position = 2, HelpMessage = "Pass array as System.Collections.ArrayList object")]
        [string[]]
        $AzurePublicDnsZoneForwarders
    )
    try {
        foreach ($Zone in $AzurePublicDnsZoneForwarders) {
            if (Get-DNSServerZone -ComputerName $DNSServerIPorName | where-object { $_.ZoneType -eq 'Forwarder' -and $_.ZoneName -eq $Zone }) {
                Remove-DnsServerZone  `
                    -Name $Zone -Force 
                Write-output "Removed conditional forward lookup zone for $Zone"
            }
        }
    }
    Catch {
        Write-Output "WOEPS:" $Error[0]
    }
    Finally {

    }
}


Function AddConditionalForwarders {
    Param(
        [Parameter(Mandatory = $False, Position = 0, HelpMessage = "Pass array as System.Collections.ArrayList object")]
        [System.Collections.ArrayList]
        $AzurePublicDnsZoneForwarders,
        [Parameter(Mandatory = $true, Position = 1, HelpMessage = "Enter the IP address(es) of the DNS server{s) as an array of strings.")]
        [string[]]
        $DnsServer2Forward2,
        [Parameter(Mandatory = $False, Position = 2, HelpMessage = "Specify the forwader time out in seconds.")]
        [Int]
        $ForwarderTimeOut = 5,
        [Parameter(Mandatory = $False, Position = 3, HelpMessage = "Scope of the DNS Partition")]
        [ValidateNotNullorEmpty()]
        [ValidateSet('Custom', 'Domain', 'Forest', 'Legacy')]
        [string]
        $DnsReplicationScope = $Null,
        [Parameter(Mandatory = $False, Position = 4, HelpMessage = "Name of DNS Partition")]
        [ValidateNotNullorEmpty()]
        [string]
        $DirectoryPartitionName = $Null
    )

    Try {
        $BuiltInPartitions = @("Forest", "Domain", "Legacy")
        foreach ($Zone in $AzurePublicDnsZoneForwarders) {
            if (!(Get-DNSServerZone -ComputerName $DNSServerIPorName | where-object { $_.ZoneType -eq 'Forwarder' -and $_.ZoneName -eq $Zone } )) {
                If ([String]::IsNullorEmpty($DnsReplicationScope)) {
                    if ($Null -ne $ForwarderTimeOut) {
                        Add-DnsServerConditionalForwarderZone -ComputerName $DNSServerIPorName `
                            -Name $Zone `
                            -MasterServers $DnsServer2Forward2 `
                            -ForwarderTimeout $ForwarderTimeOut
                        Write-output "Added conditional forward lookup zone for $Zone with Timeout value $ForwarderTimeOut seconds"
                    }
                    else {
                        Add-DnsServerConditionalForwarderZone -ComputerName $DNSServerIPorName `
                            -Name $Zone `
                            -MasterServers $DnsServer2Forward2
                        Write-output "Added conditional forward lookup zone for $Zone"
                        return
                    }
                }
                ElseIf ($DnsReplicationScope -in $BuiltInPartitions) {
                    if ($Null -ne $ForwarderTimeOut) {
                        Add-DnsServerConditionalForwarderZone -ComputerName $DNSServerIPorName `
                            -Name $Zone `
                            -MasterServers $DnsServer2Forward2 `
                            -ForwarderTimeout $ForwarderTimeOut `
                            -ReplicationScope $DnsReplicationScope
                        Write-output "Added conditional forward lookup zone for $Zone with Timeout value $ForwarderTimeOut seconds. It is AD integrated and replicates to the builtin partition $DnsReplicationScope."
                    }
                    else {
                        Add-DnsServerConditionalForwarderZone -ComputerName $DNSServerIPorName `
                            -Name $Zone `
                            -MasterServers $DnsServer2Forward2 `
                            -ReplicationScope $DnsReplicationScope
                        Write-output "Added conditional forward lookup zone for $Zone"
                    }
                }
                Else {
                    if ($Null -ne $ForwarderTimeOut) {
                        Add-DnsServerConditionalForwarderZone -ComputerName $DNSServerIPorName `
                            -Name $Zone `
                            -MasterServers $DnsServer2Forward2 `
                            -ForwarderTimeout $ForwarderTimeOut `
                            -ReplicationScope $DnsReplicationScope `
                            -DirectoryPartitionName $DirectoryPartitionName
                        Write-output "Added conditional forward lookup zone for $Zone with Timeout value $ForwarderTimeOut seconds. It is AD integrated and replicates to custom partition $DirectoryPartitionName."
                    }
                    else {
                        Add-DnsServerConditionalForwarderZone -ComputerName $DNSServerIPorName `
                            -Name $Zone `
                            -MasterServers $DnsServer2Forward2 `
                            -ReplicationScope $DnsReplicationScope `
                            -DirectoryPartitionName $DirectoryPartitionName
                        Write-output "Added conditional forward lookup zone for $Zone"
                    }               
                }                          
            }
        }
    }

    Catch {
        Write-Output Write-Output "An error has occured:" $Error[0]

        if ($Error[0].categoryInfo.category -eq 'ResourceExists') { Write-output "Duplicate Azure DNS forwarder FQDN: $($Error[0].categoryInfo.targetname), no need to add it again." }
        Else { Write-Output "An error has occured:" $Error[0] }

    }
    Finally {
    }

}
Function UpdateConditionalForwarders {
    Param(
        [Parameter(Mandatory = $True, Position = 0, HelpMessage = "Pass array as System.Collections.ArrayList object")]
        [System.Collections.ArrayList]
        $AzurePublicDnsZoneForwarders,
        [Parameter(Mandatory = $False, Position = 1, HelpMessage = "Enter the IP address(es) of the DNS server{s) as an array of strings.")]
        [string[]]
        $UpdateDnsServer2Forward2,
        [Parameter(Mandatory = $False, Position = 2, HelpMessage = "Specify the forwader time out in seconds.")]
        [Int]
        $ForwarderTimeOut = $Null
    )
    Try {

        if ($null -ne $UpdateDnsServer2Forward2 -and $Null -ne $ForwarderTimeOut) {
            Write-Output "You must specify the DNS Server IP(s), the TimeOut value or both"
            return
        }
        foreach ($Zone in $AzurePublicDnsZoneForwarders) {
            if ($null -ne $UpdateDnsServer2Forward2) {
                if ((Get-DNSServerZone -ComputerName $DNSServerIPorName | where-object { $_.ZoneType -eq 'Forwarder' -and $_.ZoneName -eq $Zone } )) {
                    [string[]]$Q = (Get-DNSServerZone -ComputerName $DNSServerIPorName | where-object { $_.ZoneType -eq 'Forwarder' -and $_.ZoneName -eq $Zone } | Select-Object -Property MasterServers -ExpandProperty MasterServers).IPAddressToString
                    $UpdateDnsServer2Forward2 | ForEach-Object {
                        if ($_ -in $Q) {
                            Write-output "$Zone Array value is the same in both DNS server IP address arrays: $_"
                        }
                        else {
                            Write-output  "$Zone Array value is different in both DNS server IP address arrays: $_"
                            Set-DnsServerConditionalForwarderZone -ComputerName $DNSServerIPorName `
                                -Name $Zone `
                                -MasterServers $UpdateDnsServer2Forward2
                            Write-output "    ||==> Updated DNS server for conditional forward lookup zone for $Zone to $UpdateDnsServer2Forward2"
                            continue
                        }
                    }
                }
            }
        }
        $Counter

        if ($Null -ne $ForwarderTimeOut) {
            if ((Get-DNSServerZone -ComputerName $DNSServerIPorName | where-object { $_.ZoneType -eq 'Forwarder' -and $_.ZoneName -eq $Zone } )) {
                Set-DnsServerConditionalForwarderZone -ComputerName $DNSServerIPorName `
                    -Name $Zone `
                    -ForwarderTimeout $ForwarderTimeOut
            }
        }
    }

    Catch {
        if ($Error[0].categoryInfo.category -eq 'ResourceExists') { Write-output "Duplicate Azure DNS forwarder FQDN: $($Error[0].categoryInfo.targetname), no need to add it again." }
        Else { Write-Output "An error has occured:" $Error[0] }
    }
    Finally {
    }

}


Function RunAzureConditionalForwarderMaintenance {

    Param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "This path and CSV file with the Azure Zone host names")]
        [ValidateNotNullorEmpty()]
        [string]
        $DNSServerIPorName,
        [Parameter(Mandatory = $true, Position = 1, HelpMessage = "This path and CSV file with the Azure Zone host names")]
        [ValidateNotNullorEmpty()]
        [string]
        $CsvFilePath,
        [Parameter(Mandatory = $true, Position = 2, HelpMessage = "Enter the IP address(es) of the DNS server{s) as an array of strings.")]
        [ValidateNotNullorEmpty()]
        [String[]]
        $DnsServer2Forward2,
        [Parameter(Mandatory = $False, Position = 3, HelpMessage = "Enter the Azure regions for which you want to create respecive conditional forwarders.")]
        [ValidateNotNullorEmpty()]
        [string[]]
        $HARegions = $Null,
        [Parameter(Mandatory = $false, Position = 4, HelpMessage = "Enter the partition IDs of any static web apps, if applicable, for which you want to create respecive conditional forwarders.")]
        [ValidateNotNullorEmpty()]
        [string[]]
        $PartitionIDs = $Null,
        [Parameter(Mandatory = $false, Position = 5, HelpMessage = "Enter the Azure SQL instance and DB, if applicable, for which you want to create respecive conditional forwarders.")]
        [ValidateNotNullorEmpty()]
        [string[]]
        $InstanceDotDB = $Null,
        [Parameter(Mandatory = $True, Position = 6, HelpMessage = "Valid actions are: Add, Remove, Update")]
        [ValidateSet('Add', 'Remove', 'Update')]
        [string]
        $Action,
        [Parameter(Mandatory = $False, Position = 7, HelpMessage = "Specify the forwader time out in seconds.")]
        [ValidateNotNullorEmpty()]
        [Int]
        $ForwarderTimeOut = $Null,
        [Parameter(Mandatory = $False, Position = 8, HelpMessage = "Scope of the DNS Partition")]
        [ValidateNotNullorEmpty()]
        [ValidateSet('Custom', 'Domain', 'Forest', 'Legacy')]
        [string]
        $DnsReplicationScope = $Null,
        [Parameter(Mandatory = $False, Position = 8, HelpMessage = "Name of DNS Partition")]
        [ValidateNotNullorEmpty()]
        [string]
        $DNSPartition = $Null
    )

    #Load  Azure public DNS zones from CSV file (table as shown in https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-dns)
    [System.Collections.ArrayList]$data = Import-Csv $CsvFilePath -delimiter ';'

    #Grab only the public DNS Zone forwarders to add as conditional forwarding zone on the on-premises DNS servers (non-AD integrated)
    [System.Collections.ArrayList]$AllAzurePublicDnsZoneForwarders = $data.('Public DNS zone forwarders') #Note this automagically drops the header as well. No need for | select -skip 1 to remove header


    #remove duplicates - some Azure services have the same
    [System.Collections.ArrayList]$AllAzurePublicDnsZoneForwarders = $AllAzurePublicDnsZoneForwarders | Sort-Object | Get-Unique

    #The MSFT table at can have empty rows, get rid of them.
    [System.Collections.ArrayList]$NoEmptiesAllAzurePublicDnsZoneForwarders = RemoveEmptyZones -AzurePublicDnsZoneForwarders $AllAzurePublicDnsZoneForwarders
    #$NoEmptiesAllAzurePublicDnsZoneForwarders

    #If you choose to create Region based entries for the desired regions is is done here, if not, the {region} place holder based rows are removed and not added.
    [System.Collections.ArrayList]$NoEmptiesWithRegionsAllAzurePublicDnsZoneForwarders = CreateRegionZones -AzurePublicDnsZoneForwarders $NoEmptiesAllAzurePublicDnsZoneForwarders -HARegions $HARegions
    #$NoEmptiesWithRegionsAllAzurePublicDnsZoneForwarders

    #If you choose to create partition Id based entries for the desired partitions is done here, if not, the {partitionId} place holder based rows are removed and not added.
    [System.Collections.ArrayList]$NoEmptiesWithRegionsWithPartitionsAllAzurePublicDnsZoneForwarders = CreatePartitionZones -AzurePublicDnsZoneForwarders $NoEmptiesWithRegionsAllAzurePublicDnsZoneForwarders -PartitionIDs $PartitionIDs
    #$NoEmptiesWithRegionsWithPartitionsAllAzurePublicDnsZoneForwarders

    #If you choose to create SQL instance based entries for the desired SQL instances is done here, if not, the {instance.{db} place holder based rows are removed and not added.
    [System.Collections.ArrayList]$NoEmptiesWithRegionsWithPartitionsSqlInstancesAllAzurePublicDnsZoneForwarders = CreateSqlInstances -AzurePublicDnsZoneForwarders $NoEmptiesWithRegionsWithPartitionsAllAzurePublicDnsZoneForwarders -InstanceDotDB $InstanceDotDB
    #$NoEmptiesWithRegionsWithPartitionsSqlInstancesAllAzurePublicDnsZoneForwarders

    #if ([String]::IsNullorEmpty($DnsReplicationScope)) { WRIte-Host -ForegroundColor MAGENTA  "BS: $DnsReplicationScope" }

    #if ([String]::IsNullorEmpty($DnsReplicationScope)) { WRIte-Host -ForegroundColor RED  "BS: $DnsReplicationScope" }
    Switch ($Action) {
        'Add' {
        
            If ( [String]::IsNullorEmpty($DnsReplicationScope)) {
                #wRITE-HOST -ForegroundColor yELLOW "Part: $DNsPartition "
                AddConditionalForwarders -AzurePublicDnsZoneForwarders $NoEmptiesWithRegionsWithPartitionsSqlInstancesAllAzurePublicDnsZoneForwarders -DnsServer2Forward2 $DnsServer2Forward2
            }
            Else {
                if ([String]::IsNullorEmpty($DNsPartition)) {
                   # wRITE-HOST -ForegroundColor gREEN "Part: $DNsPartition  "
                    AddConditionalForwarders -AzurePublicDnsZoneForwarders $NoEmptiesWithRegionsWithPartitionsSqlInstancesAllAzurePublicDnsZoneForwarders -DnsServer2Forward2 $DnsServer2Forward2 -DnsReplicationScope $DnsReplicationScope
                }
                Else {
                   # wRITE-HOST -ForegroundColor Yellow "Part: $DNsPartition  "
                    AddConditionalForwarders -AzurePublicDnsZoneForwarders $NoEmptiesWithRegionsWithPartitionsSqlInstancesAllAzurePublicDnsZoneForwarders -DnsServer2Forward2 $DnsServer2Forward2 -DirectoryPartitionName $DNsPartition -DnsReplicationScope $DnsReplicationScope
                }
            }
        }
 
        'Remove' { RemoveConditionalForwarders -AzurePublicDnsZoneForwarders $NoEmptiesWithRegionsWithPartitionsSqlInstancesAllAzurePublicDnsZoneForwarders }
        'Update' { UpdateConditionalForwarders -AzurePublicDnsZoneForwarders $NoEmptiesWithRegionsWithPartitionsSqlInstancesAllAzurePublicDnsZoneForwarders -UpdateDnsServer2Forward2 $DnsServer2Forward2 -ForwarderTimeOut $ForwarderTimeOut }
    }
}



#Load  Azure public DNS zones from CSV file
$CsvFilePath = "C:\SysAdmin\Scripting\AzurePublicDnsZoneForwarders\AzurePublicDnsZoneForwarders.csv" #Loading CSV file
[System.Collections.ArrayList]$data = Import-Csv $CsvFilePath -delimiter ';'


$DnsServer2Forward2 = @('172.16.100.101', '172.16.100.102') #Custom DNS server(s) or your Firewall DNS proxy in Azure
$UpdateDnsServer2Forward2 = @('192.168.100.101', '192.168.100.102')
$ForwarderTimeOut = 8
#If you do not want to use any region, leave the variable empty or Null
$HARegions = 'westeurope', 'northeurope'
#If you do not want to use any partition IDs with static apps, leave the variable empty or Null
$PartitionIDs = '1', '2'
#If you do not want to use any SQL Server Instace / DNS Prefix entries leave the variable empty or Null
$InstanceDotDB = 'instance1.db1', 'instance2.db1'
$DNSServer = '192.168.2.30'
#$DNSPartition = 'OP-BLUE-ADDS-SITE'
#$DnsReplicationScope = 'Forest'

$action = 'Remove'
RunAzureConditionalForwarderMaintenance -DNSServerIPorName $DNSServer -Action $action -CsvFilePath $CsvFilePath -DnsServer2Forward2 $DnsServer2Forward2 -HARegions $HARegions -PartitionIDs $PartitionIDs -InstanceDotDB $InstanceDotDB #-DnsReplicationScope $DnsReplicationScope -DNSPartition 'OP-BLUE-ADDS-SITE'
$action = 'Add'
RunAzureConditionalForwarderMaintenance -DNSServerIPorName $DNSServer -Action $action -CsvFilePath $CsvFilePath -DnsServer2Forward2 $DnsServer2Forward2 -HARegions $HARegions -PartitionIDs $PartitionIDs -InstanceDotDB $InstanceDotDB #-DnsReplicationScope $DnsReplicationScope -DNSPartition $DNSPartition
$action = 'Update'
#RunAzureConditionalForwarderMaintenance -DNSServerIPorName $DNSServer -Action $action -CsvFilePath $CsvFilePath -DnsServer2Forward2 $UpdateDnsServer2Forward2 -HARegions $HARegions -PartitionIDs $PartitionIDs #-InstanceDotDB $InstanceDotDB
#$DNSPartition = 'OP-BLUE-ADDS-SITE'



$DnsReplicationScope = 'Forest'
$action = 'Remove'
RunAzureConditionalForwarderMaintenance -DNSServerIPorName $DNSServer -Action $action -CsvFilePath $CsvFilePath -DnsServer2Forward2 $DnsServer2Forward2 -HARegions $HARegions -PartitionIDs $PartitionIDs -InstanceDotDB $InstanceDotDB #-DnsReplicationScope $DnsReplicationScope -DNSPartition 'OP-BLUE-ADDS-SITE'
$action = 'Add'
RunAzureConditionalForwarderMaintenance -DNSServerIPorName $DNSServer -Action $action -CsvFilePath $CsvFilePath -DnsServer2Forward2 $DnsServer2Forward2 -HARegions $HARegions -PartitionIDs $PartitionIDs -InstanceDotDB $InstanceDotDB -DnsReplicationScope $DnsReplicationScope  #-DNSPartition $DNSPartition



$DNSPartition = 'OP-BLUE-ADDS-SITE'
$DnsReplicationScope = 'Custom'
$action = 'Remove'
RunAzureConditionalForwarderMaintenance -DNSServerIPorName $DNSServer -Action $action -CsvFilePath $CsvFilePath -DnsServer2Forward2 $DnsServer2Forward2 -HARegions $HARegions -PartitionIDs $PartitionIDs -InstanceDotDB $InstanceDotDB #-DnsReplicationScope $DnsReplicationScope -DNSPartition 'OP-BLUE-ADDS-SITE'
$action = 'Add'
RunAzureConditionalForwarderMaintenance -DNSServerIPorName $DNSServer -Action $action -CsvFilePath $CsvFilePath -DnsServer2Forward2 $DnsServer2Forward2 -HARegions $HARegions -PartitionIDs $PartitionIDs -InstanceDotDB $InstanceDotDB -DnsReplicationScope $DnsReplicationScope  -DNSPartition $DNSPartition



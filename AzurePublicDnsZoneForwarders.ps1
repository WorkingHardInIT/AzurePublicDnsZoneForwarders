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
        #Check if the zone has {region} in it, If so swap out for the place holder for the regions specIfied
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
        [Parameter(Mandatory = $false, Position = 3, HelpMessage = "Enter the partition IDs of any static web apps, If applicable, for which you want to create respecive conditional forwarders.")]
        [string[]]
        $PartitionIDs
    )

    [System.Collections.ArrayList]$AllAzurePublicDnsZoneForwardersWithRegionsAndPartitions = $AzurePublicDnsZoneForwarders.Clone()
    ForEach ($Zone in $AzurePublicDnsZoneForwarders) {
        #Check if the zone has {region} in it, If so swap out for the place holder for the regions specIfied
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
        [Parameter(Mandatory = $false, Position = 3, HelpMessage = " ArrayList to enter the SQL instances & DB in '{instance}.{db),'{instance2}.{db)' format If applicable, for which you want to create respecive conditional forwarders.")]
        [string[]]
        $InstanceDotDB
    )
    [System.Collections.ArrayList]$NoEmptiesWithRegionsWithPartitionsSqlInstancesAllAzurePublicDnsZoneForwarders = $AzurePublicDnsZoneForwarders.Clone()
    ForEach ($Zone in $AzurePublicDnsZoneForwarders) {

        If (($Zone.Split('.')).Count -gt 3) {

            If ('{instanceName}.{dnsPrefix}' -eq $Zone.Substring(0, $Zone.IndexOf(".", $Zone.IndexOf(".") + 1))) {

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
        $AzurePublicDnsZoneForwarders,
        [Parameter(Mandatory = $False, Position = 9, HelpMessage = "Name or IP address of DNS Server where want to run this code. Default is local host.")]
        [ValidateNotNullorEmpty()]
        [string]
        $DNSServer = '.'
    )
    try {
        foreach ($Zone in $AzurePublicDnsZoneForwarders) {
            If (Get-DnsServerZone -ComputerName $DNSServer | Where-Object { $_.ZoneType -eq 'Forwarder' -and $_.ZoneName -eq $Zone }) {
                Remove-DnsServerZone  `
                    -Name $Zone -Force
                Write-Output "Removed conditional forward lookup zone for $Zone"
            }
        }
    }
    Catch {
        Write-Output "An error has occured:" $Error[0]
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
        [Parameter(Mandatory = $False, Position = 2, HelpMessage = "SpecIfy the forwader time out in seconds.")]
        [Int]
        $ForwarderTimeOut = $Null,
        [Parameter(Mandatory = $False, Position = 3, HelpMessage = "Scope of the DNS Partition")]
        [ValidateNotNullorEmpty()]
        [ValidateSet('Custom', 'Domain', 'Forest', 'Legacy')]
        [string]
        $DnsReplicationScope = $Null,
        [Parameter(Mandatory = $False, Position = 4, HelpMessage = "Name of DNS Partition")]
        [ValidateNotNullorEmpty()]
        [string]
        $DirectoryPartitionName = $Null,
        [Parameter(Mandatory = $False, Position = 5, HelpMessage = "Name or IP address of DNS Server where want to run this code. Default is local host.")]
        [ValidateNotNullorEmpty()]
        [string]
        $DnsServer = '.'
    )

    Try {
        $BuiltInPartitions = @("Forest", "Domain", "Legacy")
        foreach ($Zone in $AzurePublicDnsZoneForwarders) {
            If (!(Get-DnsServerZone -ComputerName $DNSServerIPorName | Where-Object { $_.ZoneType -eq 'Forwarder' -and $_.ZoneName -eq $Zone } )) {
                If ([String]::IsNullorEmpty($DnsReplicationScope)) {
                    If ($Null -ne $ForwarderTimeOut) {
                        $Params = @{
                            'ComputerName'     = $DnsServer
                            'Name'             = $Zone
                            'MasterServers'    = $DnsServer2Forward2
                            'ForwarderTimeout' = $ForwarderTimeOut
                        }
                        Add-DnsServerConditionalForwarderZone @Params
                        Write-Output "1 Added conditional forward lookup zone for $Zone with Timeout value $ForwarderTimeOut seconds"
                    }
                    Else {
                        $Params = @{
                            'ComputerName'  = $DnsServer
                            'Name'          = $Zone
                            'MasterServers' = $DnsServer2Forward2
                        }
                        Add-DnsServerConditionalForwarderZone @Params 
                        Write-Output "2 Added conditional forward lookup zone for $Zone"
                        return
                    }
                }
                ElseIf ($DnsReplicationScope -in $BuiltInPartitions) {
                    If ($Null -ne $ForwarderTimeOut) {
                        $Params = @{
                            'ComputerName'     = $DnsServer
                            'Name'             = $Zone
                            'MasterServers'    = $DnsServer2Forward2
                            'ForwarderTimeout' = $ForwarderTimeOut
                            'ReplicationScope' = $DnsReplicationScope
                        }
                        Add-DnsServerConditionalForwarderZone @Params
                        Write-Output "3 Added conditional forward lookup zone for $Zone with Timeout value $ForwarderTimeOut seconds. It is AD integrated and replicates to the builtin partition $DnsReplicationScope."
                    }
                    Else {
                        $Params = @{
                            'ComputerName'     = $DnsServer
                            'Name'             = $Zone
                            'MasterServers'    = $DnsServer2Forward2
                            'ReplicationScope' = $DnsReplicationScope
                        }
                        Add-DnsServerConditionalForwarderZone @Params
                        Write-Output "4 Added conditional forward lookup zone for $Zone"
                    }
                }
                Else {
                    If ($Null -ne $ForwarderTimeOut) {
                        $Params = @{
                            'ComputerName'           = $DnsServer
                            'Name'                   = $Zone
                            'MasterServers'          = $DnsServer2Forward2
                            'ForwarderTimeout'       = $ForwarderTimeOut
                            'ReplicationScope'       = $DnsReplicationScope
                            'DirectoryPartitionName' = $DirectoryPartitionName
                        }
                        Add-DnsServerConditionalForwarderZone @Params
                        Write-Output "5 Added conditional forward lookup zone for $Zone with Timeout value $ForwarderTimeOut seconds. It is AD integrated and replicates to custom partition $DirectoryPartitionName."
                    }
                    Else {
                        $Params = @{
                            'ComputerName'           = $DnsServer
                            'Name'                   = $Zone
                            'MasterServers'          = $DnsServer2Forward2
                            'ReplicationScope'       = $DnsReplicationScope
                            'DirectoryPartitionName' = $DirectoryPartitionName
                        }
                        Add-DnsServerConditionalForwarderZone @Params
                        Write-Output "6 Added conditional forward lookup zone for $Zone"
                    }               
                }                          
            }
        }
    }

    Catch {
        Write-Output Write-Output "An error has occured:" $Error[0]
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
        [Parameter(Mandatory = $False, Position = 2, HelpMessage = "SpecIfy the forwader time out in seconds.")]
        [Int]
        $ForwarderTimeOut = $Null,
        [Parameter(Mandatory = $False, Position = 3, HelpMessage = "Name or IP address of DNS Server where want to run this code. Default is local host.")]
        [ValidateNotNullorEmpty()]
        [string]
        $DnsServer = '.'
    )
    Try {

        If ($null -eq $UpdateDnsServer2Forward2 -and $Null -eq $ForwarderTimeOut) {
            Write-Output "You must specIfy the DNS Server IP(s), the TimeOut value or both"
            return
        }
        foreach ($Zone in $AzurePublicDnsZoneForwarders) {
            If ($null -ne $UpdateDnsServer2Forward2) {
                If ((Get-DnsServerZone -ComputerName $DNSServerIPorName | Where-Object { $_.ZoneType -eq 'Forwarder' -and $_.ZoneName -eq $Zone } )) {
                    [string[]]$CurrentIpAddressesOfForwarder = (Get-DnsServerZone -ComputerName $DNSServerIPOrName | Where-Object { $_.ZoneType -eq 'Forwarder' -and $_.ZoneName -eq $Zone } | Select-Object -Property MasterServers -ExpandProperty MasterServers).IPAddressToString
                    $PrintCurrentIpAddressesOfForwarder = $CurrentIpAddressesOfForwarder -join ";"
                    $UpdateDnsServer2Forward2 | ForEach-Object {
                        If ($_ -in $CurrentIpAddressesOfForwarder) {
                            Write-Output "$Zone Array value is the same in both DNS server IP address arrays: $PrintCurrentIpAddressesOfForwarder."
                        }
                        Else {
                            Write-Output  "$Zone Array value is different in both DNS server IP address arrays: $PrintCurrentIpAddressesOfForwarder."
                            $Params = @{
                                'ComputerName'  = $DnsServer
                                'Name'          = $Zone
                                'MasterServers' = $DnsServer2Forward2
                            }
                            Set-DnsServerConditionalForwarderZone @Params
                            $PrintUpdateDnsServer2Forward2 = $UpdateDnsServer2Forward2 -join ";"
                            Write-Output "    ||==> Updated DNS server for conditional forward lookup zone for $Zone to $PrintUpdateDnsServer2Forward2"
                            continue
                        }
                    }
                }
            }
        }

        If ($Null -ne $ForwarderTimeOut) {
            If ((Get-DnsServerZone -ComputerName $DNSServerIPorName | Where-Object { $_.ZoneType -eq 'Forwarder' -and $_.ZoneName -eq $Zone } )) {
                $Params = @{
                    'ComputerName'     = $DnsServer
                    'Name'             = $Zone
                    'ForwarderTimeout' = $ForwarderTimeOut
                }
                Set-DnsServerConditionalForwarderZone @Params
            }
        }
    }

    Catch {
        Write-Output "An error has occured:" $Error[0] 
    }
    Finally {
    }

}
function LoadAndFilterData {
    Param(
    [Parameter(Mandatory = $true, Position = 0, HelpMessage = "This path and CSV file with the Azure Zone host names.")]
    [ValidateNotNullorEmpty()]
    [string]
    $CsvFilePath,
    [Parameter(Mandatory = $true, Position = 1, HelpMessage = "Enter the IP address(es) of the DNS server{s) to forward to as an array of strings.")]
    [ValidateNotNullorEmpty()]
    [String[]]
    $DnsServer2Forward2,
    [Parameter(Mandatory = $False, Position = 2, HelpMessage = "Enter the Azure regions for which you want to create respecive conditional forwarders.")]
    [ValidateNotNullorEmpty()]
    [string[]]
    $HARegions = $Null,
    [Parameter(Mandatory = $false, Position = 3, HelpMessage = "Enter the partition IDs of any static web apps, If applicable, for which you want to create respecive conditional forwarders.")]
    [ValidateNotNullorEmpty()]
    [string[]]
    $PartitionIDs = $Null,
    [Parameter(Mandatory = $false, Position = 4, HelpMessage = "Enter the Azure SQL instance and DB, If applicable, for which you want to create respecive conditional forwarders.")]
    [ValidateNotNullorEmpty()]
    [string[]]
    $InstanceDotDB = $Null
    )

   #Load  Azure public DNS zones from CSV file (table as shown in https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-dns)
    [System.Collections.ArrayList]$csvContents = Import-Csv $CsvFilePath -Delimiter ';'

    #Grab only the public DNS Zone forwarders to add as conditional forwarding zone on the on-premises DNS servers (non-AD integrated)
    [System.Collections.ArrayList]$AllAzurePublicDnsZoneForwarders = $csvContents.('Public DNS zone forwarders') #Note this automagically drops the header as well. No need for | select -skip 1 to remove header


    #remove duplicates - some Azure services have the same
    [System.Collections.ArrayList]$AllAzurePublicDnsZoneForwarders = $AllAzurePublicDnsZoneForwarders | Sort-Object | Get-Unique

    #The MSFT table at can have empty rows, get rid of them.
    [System.Collections.ArrayList]$NoEmptiesAllAzurePublicDnsZoneForwarders = RemoveEmptyZones -AzurePublicDnsZoneForwarders $AllAzurePublicDnsZoneForwarders
    #$NoEmptiesAllAzurePublicDnsZoneForwarders

    #If you choose to create Region based entries for the desired regions is is done here, If not, the {region} place holder based rows are removed and not added.
    [System.Collections.ArrayList]$NoEmptiesWithRegionsAllAzurePublicDnsZoneForwarders = CreateRegionZones -AzurePublicDnsZoneForwarders $NoEmptiesAllAzurePublicDnsZoneForwarders -HARegions $HARegions
    #$NoEmptiesWithRegionsAllAzurePublicDnsZoneForwarders

    #If you choose to create partition Id based entries for the desired partitions is done here, If not, the {partitionId} place holder based rows are removed and not added.
    [System.Collections.ArrayList]$NoEmptiesWithRegionsWithPartitionsAllAzurePublicDnsZoneForwarders = CreatePartitionZones -AzurePublicDnsZoneForwarders $NoEmptiesWithRegionsAllAzurePublicDnsZoneForwarders -PartitionIDs $PartitionIDs
    #$NoEmptiesWithRegionsWithPartitionsAllAzurePublicDnsZoneForwarders

    #If you choose to create SQL instance based entries for the desired SQL instances is done here, If not, the {instance.{db} place holder based rows are removed and not added.
    [System.Collections.ArrayList]$NoEmptiesWithRegionsWithPartitionsSqlInstancesAllAzurePublicDnsZoneForwarders = CreateSqlInstances -AzurePublicDnsZoneForwarders $NoEmptiesWithRegionsWithPartitionsAllAzurePublicDnsZoneForwarders -InstanceDotDB $InstanceDotDB
    #$NoEmptiesWithRegionsWithPartitionsSqlInstancesAllAzurePublicDnsZoneForwarders

    return $NoEmptiesWithRegionsWithPartitionsSqlInstancesAllAzurePublicDnsZoneForwarders
   
}

Function RunAzureConditionalForwarderMaintenance {
    Param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Name or IP address of DNS Server where want to run this code. Default is local host.")]
        [ValidateNotNullorEmpty()]
        [string]
        $DNSServerIpOrName,
        [Parameter(Mandatory = $true, Position = 1, HelpMessage = "This path and CSV file with the Azure Zone host names.")]
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
        [Parameter(Mandatory = $false, Position = 4, HelpMessage = "Enter the partition IDs of any static web apps, If applicable, for which you want to create respecive conditional forwarders.")]
        [ValidateNotNullorEmpty()]
        [string[]]
        $PartitionIDs = $Null,
        [Parameter(Mandatory = $false, Position = 5, HelpMessage = "Enter the Azure SQL instance and DB, If applicable, for which you want to create respecive conditional forwarders.")]
        [ValidateNotNullorEmpty()]
        [string[]]
        $InstanceDotDB = $Null,
        [Parameter(Mandatory = $false, Position = 6, HelpMessage = "Valid actions are: Add, Remove, Update.")]
        [ValidateSet('Add', 'Remove', 'Update')]
        [string]
        $Action,
        [Parameter(Mandatory = $False, Position = 7, HelpMessage = "SpecIfy the forwader time out in seconds.")]
        [ValidateNotNullorEmpty()]
        [Int]
        $ForwarderTimeOut = 5,
        [Parameter(Mandatory = $False, Position = 8, HelpMessage = "Scope of the DNS Partition.")]
        [ValidateNotNullorEmpty()]
        [ValidateSet('Custom', 'Domain', 'Forest', 'Legacy')]
        [string]
        $DnsReplicationScope = $Null,
        [Parameter(Mandatory = $False, Position = 8, HelpMessage = "Name of DNS Partition.")]
        [ValidateNotNullorEmpty()]
        [string]
        $DNSPartition = $Null
    )

    $Params = @{
        'CsvFilePath'           = $CsvFilePath
        'DnsServer2Forward2'    = $DnsServer2Forward2
        'HARegions'             = $HARegions
        'PartitionIDs'          = $PartitionIDs
        'InstanceDotDB'         = $InstanceDotDB
    }
    
    #This is the sanitized list of Azure DNS public forwarders to maintain => add, remove update."
    #We need it as a paramter to pass on to the MaintainConditionalForwarders function.
    [System.Collections.ArrayList]$AzurePublicDnsZoneForwarders = LoadAndFilterData @Params

    #If there is no replication scope in play the condotional forwarding zones are not stored in Active Directory - we do not pass this parameter
    if ([String]::IsNullorEmpty($DnsReplicationScope)){
        $Params = @{
        'AzurePublicDnsZoneForwarders'  = $AzurePublicDnsZoneForwarders
        'DNSServerIpOrName'             = $DNSServerIpOrName
        'DnsServer2Forward2'            = $DnsServer2Forward2
        'Action'                        = $Action
        'ForwarderTimeOut'              = $ForwarderTimeOut
        }
    }
    Else {
        #So if the DSNReplicationScope is a valid value we need to know if there is a partition in play, if there is not, we must not pass it as a parameter.
        If ([String]::IsNullorEmpty($DNsPartition)){
            $Params = @{
            'AzurePublicDnsZoneForwarders'  = $AzurePublicDnsZoneForwarders
            'DNSServerIpOrName'             = $DNSServerIpOrName
            'DnsServer2Forward2'            = $DnsServer2Forward2
            'Action'                        = $Action
            'ForwarderTimeOut'              = $ForwarderTimeOut
            'DnsReplicationScope'           = $DnsReplicationScope
            }
        }
        # ... if there is, we need to pass that as a parameter as well.
        else{
            $Params = @{
                'AzurePublicDnsZoneForwarders'  = $AzurePublicDnsZoneForwarders
                'DNSServerIpOrName'             = $DNSServerIpOrName
                'DnsServer2Forward2'            = $DnsServer2Forward2
                'Action'                        = $Action
                'ForwarderTimeOut'              = $ForwarderTimeOut
                'DnsReplicationScope'           = $DnsReplicationScope
                'DNsPartition'                  = $DNsPartition
        }
    }
}
    
    MaintainConditionalForwarders @Params


    
}

function MaintainConditionalForwarders {
    Param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "The list of Azure DNS public forwarders to maintain => add, remove update.")]
        [ValidateNotNullorEmpty()]
        [System.Collections.ArrayList]
        $AzurePublicDnsZoneForwarders,
        [Parameter(Mandatory = $true, Position = 1, HelpMessage = "Name or IP address of DNS Server where want to run this code. Default is local host.")]
        [ValidateNotNullorEmpty()]
        [string]
        $DNSServerIpOrName,
        [Parameter(Mandatory = $true, Position = 2, HelpMessage = "Enter the IP address(es) of the DNS server{s) to forward to as an array of strings.")]
        [ValidateNotNullorEmpty()]
        [String[]]
        $DnsServer2Forward2,
        [Parameter(Mandatory = $false, Position = 3, HelpMessage = "Valid actions are: Add, Remove, Update.")]
        [ValidateSet('Add', 'Remove', 'Update')]
        [string]
        $Action,
        [Parameter(Mandatory = $False, Position = 4, HelpMessage = "Specify the forwader time out in seconds.")]
        [ValidateNotNullorEmpty()]
        [Int]
        $ForwarderTimeOut = 5,
        [Parameter(Mandatory = $False, Position = 5, HelpMessage = "Scope of the DNS Partition.")]
        [ValidateNotNullorEmpty()]
        [ValidateSet('Custom', 'Domain', 'Forest', 'Legacy')]
        [string]
        $DnsReplicationScope = $Null,
        [Parameter(Mandatory = $False, Position = 6, HelpMessage = "Name of DNS Partition.")]
        [ValidateNotNullorEmpty()]
        [string]
        $DNSPartition = $Null
    )

    Switch ($Action) {
        'Add' {
        
            If ( [String]::IsNullorEmpty($DnsReplicationScope)) {
                AddConditionalForwarders -AzurePublicDnsZoneForwarders $AzurePublicDnsZoneForwarders `
                    -DnsServer2Forward2 $DnsServer2Forward2 -DnsServer $DNSServerIpOrName -ForwarderTimeOut $ForwarderTimeOut
            }
            Else {
                If ([String]::IsNullorEmpty($DNsPartition)) {
                    AddConditionalForwarders -AzurePublicDnsZoneForwarders $AzurePublicDnsZoneForwarders -DnsServer2Forward2 `
                        $DnsServer2Forward2 -DnsReplicationScope $DnsReplicationScope  -DnsServer $DNSServerIpOrName -ForwarderTimeOut $ForwarderTimeOut
                }
                Else {
                    AddConditionalForwarders -AzurePublicDnsZoneForwarders $AzurePublicDnsZoneForwarders -DnsServer2Forward2 $DnsServer2Forward2 `
                        -DirectoryPartitionName $DNsPartition -DnsReplicationScope $DnsReplicationScope -DnsServer $DNSServerIpOrName -ForwarderTimeOut $ForwarderTimeOut
                }
            }
        }
 
        'Remove' {
            RemoveConditionalForwarders -AzurePublicDnsZoneForwarders $AzurePublicDnsZoneForwarders -DnsServer $DNSServerIpOrName
        }
        'Update' {
            UpdateConditionalForwarders -AzurePublicDnsZoneForwarders $AzurePublicDnsZoneForwarders -UpdateDnsServer2Forward2 $DnsServer2Forward2 `
                -ForwarderTimeOut $ForwarderTimeOut -DnsServer $DNSServerIpOrName
        }
    }


}
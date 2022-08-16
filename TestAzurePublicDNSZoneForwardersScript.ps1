Clear-Host
. .\AzurePublicDnsZoneForwarders.ps1

#Load  Azure public DNS zones from CSV file that has header and is ';' seperated


#$CsvFilePath = "C:\SysAdmin\Scripting\AzurePublicDnsZoneForwarders\AzurePublicDnsZoneForwarders.csv" #Loading CSV file
$CsvFilePath = ".\AzurePublicDnsZoneForwarders.csv" #Loading CSV file

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
RunAzureConditionalForwarderMaintenance -DNSServerIPorName $DNSServer -Action $action -CsvFilePath $CsvFilePath -DnsServer2Forward2 $DnsServer2Forward2 -HARegions $HARegions -PartitionIDs $PartitionIDs -InstanceDotDB $InstanceDotDB
$action = 'Add'
RunAzureConditionalForwarderMaintenance -DNSServerIPorName $DNSServer -Action $action -CsvFilePath $CsvFilePath -DnsServer2Forward2 $DnsServer2Forward2 -HARegions $HARegions -PartitionIDs $PartitionIDs -InstanceDotDB $InstanceDotDB #-DnsReplicationScope $DnsReplicationScope -DNSPartition $DNSPartition
$action = 'Update'
RunAzureConditionalForwarderMaintenance -DNSServerIPorName $DNSServer -Action $action -CsvFilePath $CsvFilePath -DnsServer2Forward2 $UpdateDnsServer2Forward2 -HARegions $HARegions -PartitionIDs $PartitionIDs -InstanceDotDB $InstanceDotDB

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
RunAzureConditionalForwarderMaintenance -DNSServerIPorName $DNSServer -Action $action -CsvFilePath $CsvFilePath -DnsServer2Forward2 $DnsServer2Forward2 -HARegions $HARegions `
    -PartitionIDs $PartitionIDs -InstanceDotDB $InstanceDotDB -DnsReplicationScope $DnsReplicationScope  -DNSPartition $DNSPartition -ForwarderTimeOut $ForwarderTimeOut 

    


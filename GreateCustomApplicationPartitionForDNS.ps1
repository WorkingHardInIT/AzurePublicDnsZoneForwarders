#This is just demo code to show hwo to create your own custom DNS server directory partition(s)

Add-DnsServerDirectoryPartition -Name "OP-BLUE-ADDS-SITE" -ComputerName 'DC01'
Get-DnsServerDirectoryPartition -ComputerName 'DC01' |Format-Table -AutoSize
Register-DnsServerDirectoryPartition -Name "OP-BLUE-ADDS-SITE" -ComputerName 'DC02'
Get-DnsServerDirectoryPartition -Name "OP-BLUE-ADDS-SITE" -ComputerName 'DC02' | Format-Table -AutoSize

Add-DnsServerDirectoryPartition -Name "OP-RED-ADDS-SITE" -ComputerName 'DC03'
Get-DnsServerDirectoryPartition -ComputerName 'DC03' |Format-Table -AutoSize
Register-DnsServerDirectoryPartition -Name "OP-RED-ADDS-SITE" -ComputerName 'DC04'
Get-DnsServerDirectoryPartition -Name "OP-RED-ADDS-SITE" -ComputerName 'DC04' | Format-Table -AutoSize
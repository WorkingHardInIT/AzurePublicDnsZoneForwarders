See my blog post https://blog.workinghardinit.work/2022/08/09/powershell-script-to-maintain-azure-public-dns-zone-conditional-forwarders/
for more background info on this PowerShell script.
Please note that in the update part I have not (yet) implemented updating
whether the zone is stored in Active Directory or not, and if so in what way.
This is mainly due to the fact that doing so can lead to name resolution failure
due to a bug. The fix is to remove the affected zones and add them again with
the correct settings for that zone. That functionality is there. See
https://blog.workinghardinit.work/2022/08/03/bug-when-changing-the-store-this-conditional-forwarder-in-active-directory-setting/
for more information

IMPORTANT: This code is work in progress to be used and adapted for scenarios I encounter.
There is no warranty. Use is at your own risk. You are responsible for testing and
making sure it is fit for purpose in your use cases and the environments where you use it.

Details of improve commit on 2022/08/15:
    Changed the parameter list for the DNS commands from using the ` continuation character to splatting.
    $CurrentIpAddressesOfForwarder to better indicate its purpose.
    Fixed some code style inconsistencies: if => If everywhere, else => Else everywhere.
    Ik check for duplicate entries in the code so I remove the specific Catch error line for that (If ($Error[0].categoryInfo.category -eq 'ResourceExists') { Write-Output "Duplicate Azure DNS forwarder FQDN: $($Error[0].categoryInfo.targetname), no need to add it again." } ...).
    Done! $Q variable loads the current DNS Servers to check is they are equal or different to updated ones, $Q parameter is now called $CurrentIpAddressesOfForwarder.
    Fixed GreateCustomApplicationPartitionForDNS.ps1 Typo, is now CreateCustomApplicationPartitionForDNS.ps1.
    Removed orphan $counter variable.
    Renamed $data variable to $csvContents for clarity.
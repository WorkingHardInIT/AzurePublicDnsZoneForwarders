See my blog for more background info on this PowerShell script.
Please note that in the update part I have not (yet) implemented updating
whether the zone is stored in Active Directory or not, and if so in what way.
This is mainly due to the fact that doing so can lead to name resolution failure
due to a bug. The fix is to remove the affected zones and add them again with
the correct settings for that zone. That functionality is there. See
https://blog.workinghardinit.work/2022/08/03/bug-when-changing-the-store-this-conditional-forwarder-in-active-directory-setting/
for more information

IMPORTANT: This code is work in progress to be used and adapted for scenarios I encounter.
There is no waranty. Use is at your own risk. You are reponsible for testing and
making sure it is fit for purpose in your use cases and the environments where you use it.

## v0.6.11

Fixes:
 - Changed param names to be compatible with azure provider 4.x.x

## v0.6.10

Fixes:
 - Changed availability_zones_enabled default value to true

## v0.6.9

Features:

For the Windows vms:
 - Added vars identity_type, identity_ids to configure Managed Service Identity
 - Added var aad_login_for_windows to join the vms to Azure Active Directory

## v0.6.8

Features:

 - Added output network_interface_data to collect interfaces data

## v0.6.7

Fixes:

 - Changed default public_ip_address_id value from "" to null to be compatible with provider >= 3.66.0

## v0.6.6

Features:

 - Changed zone attribute of azurerm_managed_disk to be compatible with provider >= 3.x.x

## v0.6.5

Features:

 - Added the possibility to specify to use the availability zones, the vms and relevant data disks will be deployed in availability_zones_number zones, default to 3. The first vm and its data disks will be deployed on availability zone 1, the second vm and its data disks will be deployed on availability zone 2 and so on

## v0.6.4

Features:

 - Added the possibility to specify a NSG to attach to vms NICs

## v0.6.3

Features:

 - Added dns_servers variable to specify a list of dns servers for the network interface, default to []
 - Added enable_ip_forwarding variable to enable ip forwarding for the network interface, default to false

## v0.6.2

Fixes:

 - Fix README.md

## v0.6.1

Fixes:

 - Fix README.md

## v0.6.0

Features:

- Added net_ints_2_app_sec_grps local to make an array of objects to create nic to asg associations
- Added vms_2_data_disks local to make an array of objects used to associate m data disks to n vms

Limits:

- Data disks cannot be added or removed after the first deploy if the number of vms is more than one (the list of data disks will be regenerated), but is still possible to change their sizes
- If there are n vms you can safely remove only tha last one (lists of objects will be regenerated)

## v0.5.0

Features:

- Added use of resource azurerm_linux_virtual_machine and azurerm_windows_virtual_machine instead of azurerm_virtual_machine

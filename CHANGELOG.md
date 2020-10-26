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
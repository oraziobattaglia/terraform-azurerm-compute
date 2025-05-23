# Limits:
# 1. This module is used to create n vms with m data disks each.
#    ATTENTION: Data disks cannot be added or removed after the first deploy if the number of vms is more 
#    than one (the list of data disks will be regenerated), but is still possible to change their sizes.

# Tests:
# 1. Change data disk 0 size: OK (update in place)
# 2. Change data disk 1 size: OK (update in place)
# 3. Change data disk 2 size: OK (update in place)
# 4. Add data disk 3: KO (bad change in data disks list! NOT DO!)
# 5. Add a vm at the end of the list virtual_machine_names: OK (all objects created correctly)
# 6. Delete a vm not last in the list virtual_machine_names: KO (bad change in objects lists! NOT DO!) 
# 7. Delete the last vm the list virtual_machine_names: OK (remove the right objects)

locals {

  # Used to create nic to asg associations
  net_ints_2_app_sec_grps = flatten([
    for net_int in azurerm_network_interface.nic[*].id: [
      for app_sec_grp in var.application_security_group_ids : {
        network_interface_id = net_int
        application_security_group_id = app_sec_grp
      }
    ]
  ])

  # Used to create n data_disk (number of vms * number of data disks)
  vms_2_data_disks = flatten([
    for vm in var.virtual_machine_names: [
      for data_disk in var.data_disks : {
        data_disk_name    = "${vm}-datadisk-${data_disk.data_disk_lun}"
        data_disk_sa_type = data_disk.data_disk_sa_type
        data_disk_size_gb = data_disk.data_disk_size_gb
        data_disk_lun     = data_disk.data_disk_lun
        data_disk_caching = data_disk.data_disk_caching
      }
    ]
  ])

  # Create an array where each element contains interface data
  net_ints_data = flatten([
    for net_int in azurerm_network_interface.nic[*]: [
      {
        network_interface_id = net_int.id
        ip_conf_name = net_int.ip_configuration[0].name
      }
    ]
  ])  

}

# Network interface
resource "azurerm_network_interface" "nic" {
  count                         = var.virtual_machine_instances
  name                          = "${var.virtual_machine_names[count.index]}-nic"
  location                      = var.location
  resource_group_name           = var.resource_group
  
  accelerated_networking_enabled = var.enable_accelerated_networking
  ip_forwarding_enabled          = var.enable_ip_forwarding

  dns_servers                   = var.dns_servers

  ip_configuration {
    name                          = "${var.virtual_machine_names[count.index]}-ip"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = var.private_ip_address_allocation
    private_ip_address            = length(var.private_ip_addresses) > 0 ? var.private_ip_addresses[count.index] : ""
    public_ip_address_id          = length(var.public_ip_addresses) > 0 ? var.public_ip_addresses[count.index] : null
  }

  tags = var.tags
}

# Association nics to asg ids
resource "azurerm_network_interface_application_security_group_association" "nic2asg" {
  count                         = length(var.application_security_group_ids) > 0 ? length(local.net_ints_2_app_sec_grps) : 0
  network_interface_id          = local.net_ints_2_app_sec_grps[count.index].network_interface_id
  application_security_group_id = local.net_ints_2_app_sec_grps[count.index].application_security_group_id
}

# Association nics to nsg id
resource "azurerm_network_interface_security_group_association" "nic2nsg" {
  count                     = var.use_network_security_group ? var.virtual_machine_instances : 0
  network_interface_id      = azurerm_network_interface.nic[count.index].id
  network_security_group_id = var.network_security_group_id
}

# Virtual machine Linux
resource "azurerm_linux_virtual_machine" "vm-linux" {
  count                 = !var.is_windows ? var.virtual_machine_instances : 0
  name                  = "${var.virtual_machine_names[count.index]}-vm"
  location              = var.location
  resource_group_name   = var.resource_group
  availability_set_id   = var.availability_set_enabled ? var.availability_set_id : null
  network_interface_ids = [azurerm_network_interface.nic[count.index].id]
  size               = var.vm_size

  source_image_reference {
    publisher = var.vm_os_publisher
    offer     = var.vm_os_offer
    sku       = var.vm_os_sku
    version   = var.vm_os_version
  }
  
  os_disk {
    name                 = "${var.virtual_machine_names[count.index]}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = var.storage_account_type
  }

  dynamic "identity" {

    for_each = var.identity_type == "" ? toset([]) : toset([1])

    content {
        type = var.identity_type
        identity_ids = var.identity_ids
    }
  }

  computer_name  = var.virtual_machine_names[count.index]

  disable_password_authentication = false
  admin_username = var.admin_username
  admin_password = var.admin_password

  boot_diagnostics {
    storage_account_uri = var.boot_diagnostics ? var.storage_account_boot_diagnostics : ""
  }
  
  zone = var.availability_zones_enabled ? (count.index % var.availability_zones_number) + 1 : null
  tags = var.tags
}

# Virtual machine Windows
resource "azurerm_windows_virtual_machine" "vm-windows" {
  count                 = var.is_windows ? var.virtual_machine_instances : 0
  name                  = "${var.virtual_machine_names[count.index]}-vm"
  location              = var.location
  resource_group_name   = var.resource_group
  availability_set_id   = var.availability_set_enabled ? var.availability_set_id : null
  network_interface_ids = [azurerm_network_interface.nic[count.index].id]
  size                  = var.vm_size
  license_type          = var.license_type

  source_image_reference {
    publisher = var.vm_os_publisher
    offer     = var.vm_os_offer
    sku       = var.vm_os_sku
    version   = var.vm_os_version
  }

  os_disk {
    name                 = "${var.virtual_machine_names[count.index]}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = var.storage_account_type
  }

  dynamic "identity" {

    for_each = var.identity_type == "" ? toset([]) : toset([1])

    content {
        type = var.identity_type
        identity_ids = var.identity_ids
    }
  }

  computer_name  = var.virtual_machine_names[count.index]

  admin_username = var.admin_username
  admin_password = var.admin_password

  provision_vm_agent = true

  boot_diagnostics {
    storage_account_uri = var.boot_diagnostics ? var.storage_account_boot_diagnostics : ""
  }

  zone = var.availability_zones_enabled ? (count.index % var.availability_zones_number) + 1 : null
  tags = var.tags
}

# Create optionals data disks
resource "azurerm_managed_disk" "vm-data-disk" {
  count                = length(local.vms_2_data_disks) > 0 ? length(local.vms_2_data_disks) : 0

  name                 = local.vms_2_data_disks[count.index].data_disk_name
  location             = var.location
  resource_group_name  = var.resource_group
  storage_account_type = local.vms_2_data_disks[count.index].data_disk_sa_type
  create_option        = "Empty"
  disk_size_gb         = local.vms_2_data_disks[count.index].data_disk_size_gb

  zone = var.availability_zones_enabled ? ((floor(count.index / length(var.data_disks))) % var.availability_zones_number) + 1 : null

  tags = var.tags
}

# Data disk association
# Linux vm
resource "azurerm_virtual_machine_data_disk_attachment" "data-disk2vm-linux" {
  count = (length(local.vms_2_data_disks) > 0) && !var.is_windows ? length(local.vms_2_data_disks) : 0
  managed_disk_id = azurerm_managed_disk.vm-data-disk[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.vm-linux[floor(count.index / length(var.data_disks))].id
  lun     = local.vms_2_data_disks[count.index].data_disk_lun
  caching = local.vms_2_data_disks[count.index].data_disk_caching
}

# Windows vm
resource "azurerm_virtual_machine_data_disk_attachment" "data-disk2vm-windows" {
  count = (length(local.vms_2_data_disks) > 0) && var.is_windows ? length(local.vms_2_data_disks) : 0
  managed_disk_id = azurerm_managed_disk.vm-data-disk[count.index].id
  virtual_machine_id = azurerm_windows_virtual_machine.vm-windows[floor(count.index / length(var.data_disks))].id
  lun     = local.vms_2_data_disks[count.index].data_disk_lun
  caching = local.vms_2_data_disks[count.index].data_disk_caching
}

# JsonADDomainExtension extension
resource "azurerm_virtual_machine_extension" "vm-windows-joinext" {
  count               = var.join && var.is_windows ? var.virtual_machine_instances : 0
  name                = "${var.virtual_machine_names[count.index]}-joinext"
  virtual_machine_id  = azurerm_windows_virtual_machine.vm-windows[count.index].id

  publisher            = "Microsoft.Compute"
  type                 = "JsonADDomainExtension"
  type_handler_version = "1.3"

  settings = <<SETTINGS
    {
      "Name": "${var.windows_domain_name}",
      "User": "${var.windows_domain_username}",
      "Restart": "false",
      "Options": "3"
    }
  SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
      "Password": "${var.windows_domain_password}"
    }
  PROTECTED_SETTINGS

  tags = var.tags
}

# AADLoginForWindows extension
resource "azurerm_virtual_machine_extension" "vm-windows-aadjoinext" {
  count               = var.aad_login_for_windows && var.is_windows ? var.virtual_machine_instances : 0
  name                = "${var.virtual_machine_names[count.index]}-aadjoinext"
  virtual_machine_id  = azurerm_windows_virtual_machine.vm-windows[count.index].id

  publisher            = "Microsoft.Azure.ActiveDirectory"
  type                 = "AADLoginForWindows"
  type_handler_version = "1.0"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
      "mdmId": ""
    }
  SETTINGS

  tags = var.tags
}

# AADSSHLoginForLinux extension
resource "azurerm_virtual_machine_extension" "vm-linux-aadsshloginext" {
  count = var.aad_ssh_login_for_linux && !var.is_windows ? var.virtual_machine_instances : 0
  name = "${var.virtual_machine_names[count.index]}-aadsshloginext"

  virtual_machine_id = azurerm_linux_virtual_machine.vm-linux[count.index].id
  publisher = "Microsoft.Azure.ActiveDirectory"
  type = "AADSSHLoginForLinux"
  type_handler_version = "1.0"
  auto_upgrade_minor_version = true

  tags = var.tags
}

# Custom script extension
resource "azurerm_virtual_machine_extension" "vm-windows-cse" {
  count               = var.customize && var.is_windows ? var.virtual_machine_instances : 0
  name                = "${var.virtual_machine_names[count.index]}-cse"
  virtual_machine_id  = azurerm_windows_virtual_machine.vm-windows[count.index].id

  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  # Works only if container custom-script-extension has read permission by anonymous (access level container)
  settings = <<SETTINGS
      {
        "fileUris": [
              "${var.windows_cs_file_uri}"
            ],
        "commandToExecute": "${var.windows_cs_command}"
      }
  SETTINGS

  tags = var.tags
}

resource "azurerm_virtual_machine_extension" "vm-linux-cse" {
  count = var.customize && !var.is_windows ? var.virtual_machine_instances : 0
  name = "${var.virtual_machine_names[count.index]}-cse"

  virtual_machine_id = azurerm_linux_virtual_machine.vm-linux[count.index].id
  publisher = "Microsoft.Azure.Extensions"
  type = "CustomScript"
  type_handler_version = "2.0"

  # Works only if container custom-script-extension has read permission by anonymous (access level container)
  settings = <<SETTINGS
      {
        "fileUris": [
              "${var.linux_cs_file_uri}"
            ],
        "commandToExecute": "${var.linux_cs_command}"
      }
  SETTINGS

  tags = var.tags
}
# End Custom script extension

# Backup policy for the virtual machine
resource "azurerm_backup_protected_vm" "rs-protected-vm" {
  count               = var.backup_enabled ? var.virtual_machine_instances : 0
  resource_group_name = var.recovery_vault_resource_group
  recovery_vault_name = var.recovery_vault_name
  source_vm_id = var.is_windows ? azurerm_windows_virtual_machine.vm-windows[count.index].id : azurerm_linux_virtual_machine.vm-linux[count.index].id
  backup_policy_id = var.backup_policy_id
  
  # TO TRY! It's seem tags don't work on this resource
  # tags = "${var.tags}"
}

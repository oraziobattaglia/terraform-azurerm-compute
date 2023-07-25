# This module is based on the 2 resources azurerm_linux_virtual_machine and azurerm_windows_virtual_machine.
# Data disks are created as separate resource and attached to the vm.
# Only 1 data disks per vm is supported.
# Need provider 2.7.0 or newer.

# Network interface
resource "azurerm_network_interface" "nic" {
  count                         = var.virtual_machine_instances
  name                          = "${var.virtual_machine_names[count.index]}-nic"
  location                      = var.location
  resource_group_name           = var.resource_group
  # network_security_group_id     = var.network_security_group_id
  enable_accelerated_networking = var.enable_accelerated_networking 

  ip_configuration {
    name                          = "${var.virtual_machine_names[count.index]}-ip"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = var.private_ip_address_allocation
    private_ip_address            = length(var.private_ip_addresses) > 0 ? var.private_ip_addresses[count.index] : ""
    public_ip_address_id          = length(var.public_ip_addresses) > 0 ? var.public_ip_addresses[count.index] : null
  }

  tags = var.tags
}

# Association nic to asg ids
resource "azurerm_network_interface_application_security_group_association" "nic2asg" {
  count                         = var.virtual_machine_instances * length(var.application_security_group_ids)
  network_interface_id          = azurerm_network_interface.nic[count.index % var.virtual_machine_instances].id
  application_security_group_id = var.application_security_group_ids[floor(count.index / var.virtual_machine_instances)]
}

# Virtual machine Linux
resource "azurerm_linux_virtual_machine" "vm-linux" {
  count                 = !var.is_windows ? var.virtual_machine_instances : 0
  name                  = "${var.virtual_machine_names[count.index]}-vm"
  location              = var.location
  resource_group_name   = var.resource_group
  # availability_set_id   = var.availability_set_enabled ? join("", azurerm_availability_set.vm-avset.*.id) : null
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
  
  computer_name  = var.virtual_machine_names[count.index]

  disable_password_authentication = false
  admin_username = var.admin_username
  admin_password = var.admin_password

  boot_diagnostics {
    storage_account_uri = var.boot_diagnostics ? var.storage_account_boot_diagnostics : ""
  }
  
  tags = var.tags
}

# Virtual machine Windows
resource "azurerm_windows_virtual_machine" "vm-windows" {
  count                 = var.is_windows ? var.virtual_machine_instances : 0
  name                  = "${var.virtual_machine_names[count.index]}-vm"
  location              = var.location
  resource_group_name   = var.resource_group
  # availability_set_id   = var.availability_set_enabled ? join("", azurerm_availability_set.vm-avset.*.id) : null
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

  computer_name  = var.virtual_machine_names[count.index]

  admin_username = var.admin_username
  admin_password = var.admin_password

  provision_vm_agent = true

  boot_diagnostics {
    storage_account_uri = var.boot_diagnostics ? var.storage_account_boot_diagnostics : ""
  }

  tags = var.tags
}

# Create data disk if var.data_disk is true
resource "azurerm_managed_disk" "vm-data-disk" {
  count                = var.data_disk ? var.virtual_machine_instances : 0
  name                 = "${var.virtual_machine_names[count.index]}-datadisk"
  location             = var.location
  resource_group_name  = var.resource_group
  storage_account_type = var.data_sa_type
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size_gb

  tags = var.tags
}

# Data disk association
# Linux vm
resource "azurerm_virtual_machine_data_disk_attachment" "data-disk2vm-linux" {
  count = var.data_disk && !var.is_windows ? var.virtual_machine_instances : 0
  managed_disk_id = azurerm_managed_disk.vm-data-disk[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.vm-linux[count.index].id
  lun     = "0"
  caching = var.data_disk_caching
}

# Windows vm
resource "azurerm_virtual_machine_data_disk_attachment" "data-disk2vm-windows" {
  count = var.data_disk && var.is_windows ? var.virtual_machine_instances : 0
  managed_disk_id = azurerm_managed_disk.vm-data-disk[count.index].id
  virtual_machine_id = azurerm_windows_virtual_machine.vm-windows[count.index].id
  lun     = "0"
  caching = var.data_disk_caching
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

# Custom script extension
resource "azurerm_virtual_machine_extension" "vm-windows-cse" {
  count               = var.customize && var.is_windows ? var.virtual_machine_instances : 0
  name                = "${var.virtual_machine_names[count.index]}-cse"
  virtual_machine_id  = azurerm_windows_virtual_machine.vm-windows[count.index].id

  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

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

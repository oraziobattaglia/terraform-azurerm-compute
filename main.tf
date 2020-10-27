# Questo modulo distingue solo tra vm linux e windows. I data disk vengono creati
# come oggetti separati e poi attaccati alle vm.
# Questa soluzione, migliore, funziona grazie al provider 1.31.0

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
    public_ip_address_id          = length(var.public_ip_addresses) > 0 ? var.public_ip_addresses[count.index] : ""
  }

  tags = var.tags
}

# Association nic to asg ids
resource "azurerm_network_interface_application_security_group_association" "nic2asg" {
  count                         = var.virtual_machine_instances * length(var.application_security_group_ids)
  network_interface_id          = azurerm_network_interface.nic[count.index % var.virtual_machine_instances].id
  # ip_configuration_name         = "${var.virtual_machine_names[count.index % var.virtual_machine_instances]}-ip"
  application_security_group_id = var.application_security_group_ids[floor(count.index / var.virtual_machine_instances)]
}

# Virtual machine Linux
resource "azurerm_virtual_machine" "vm-linux" {
  count                 = !var.is_windows ? var.virtual_machine_instances : 0
  name                  = "${var.virtual_machine_names[count.index]}-vm"
  location              = var.location
  resource_group_name   = var.resource_group
  availability_set_id   = var.availability_set_enabled ? join("", azurerm_availability_set.vm-avset.*.id) : ""
  network_interface_ids = [azurerm_network_interface.nic[count.index].id]
  vm_size               = var.vm_size

  delete_os_disk_on_termination    = var.delete_os_disk_on_termination
  delete_data_disks_on_termination = var.delete_data_disk_on_termination

  storage_image_reference {
    publisher = var.vm_os_publisher
    offer     = var.vm_os_offer
    sku       = var.vm_os_sku
    version   = var.vm_os_version
  }
  storage_os_disk {
    name              = "${var.virtual_machine_names[count.index]}-osdisk"
    create_option     = var.os_create_option
    caching           = "ReadWrite"
    # disk_size_gb      = var.use_custom_os_disk_size ? var.os_disk_size_gb : ""
    managed_disk_type = var.storage_account_type
  }
  os_profile {
    computer_name  = var.virtual_machine_names[count.index]
    admin_username = var.admin_username
    admin_password = var.admin_password
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  boot_diagnostics {
    enabled     = var.boot_diagnostics
    storage_uri = var.boot_diagnostics ? var.storage_account_boot_diagnostics : ""
  }
  tags = var.tags

  # # If Ubuntu 18.04 or 16.04 copies and run the customize_linux.sh script
  # # Non funziona per le vm nella vnet vNET-FE_EXT, meglio usare la virtual machine extension
  # provisioner "remote-exec" {
  #   script = "${path.module}/conf/customize_linux.bash"

  #   connection {
  #     type        = "ssh"
  #     user        = "${var.admin_username}"
  #     password    = "${var.admin_password}"
  #     script_path = "/home/${var.admin_username}/customize_linux.bash"
  #   }    
  # }
}

# Virtual machine Windows
resource "azurerm_virtual_machine" "vm-windows" {
  count                 = var.is_windows ? var.virtual_machine_instances : 0
  name                  = "${var.virtual_machine_names[count.index]}-vm"
  location              = var.location
  resource_group_name   = var.resource_group
  availability_set_id   = var.availability_set_enabled ? join("", azurerm_availability_set.vm-avset.*.id) : ""
  network_interface_ids = [azurerm_network_interface.nic[count.index].id]
  vm_size               = var.vm_size
  license_type          = var.license_type

  delete_os_disk_on_termination    = var.delete_os_disk_on_termination
  delete_data_disks_on_termination = var.delete_data_disk_on_termination

  storage_image_reference {
    publisher = var.vm_os_publisher
    offer     = var.vm_os_offer
    sku       = var.vm_os_sku
    version   = var.vm_os_version
  }
  storage_os_disk {
    name              = "${var.virtual_machine_names[count.index]}-osdisk"
    create_option     = "FromImage"
    caching           = "ReadWrite"
    # disk_size_gb      = var.use_custom_os_disk_size ? var.os_disk_size_gb : ""
    managed_disk_type = var.storage_account_type
  }
  os_profile {
    computer_name  = var.virtual_machine_names[count.index]
    admin_username = var.admin_username
    admin_password = var.admin_password
  }
  os_profile_windows_config {
    provision_vm_agent = true
  }
  boot_diagnostics {
    enabled     = var.boot_diagnostics
    storage_uri = var.boot_diagnostics ? var.storage_account_boot_diagnostics : ""
  }
  tags = var.tags

  # # Non funziona la connessione winrm (tcp port 5985) perché la vm non è in join
  # provisioner "remote-exec" {
  #   script = "${path.module}/conf/customize_windows.ps1"

  #   connection {
  #     type        = "winrm"
  #     user        = "${var.admin_username}"
  #     password    = "${var.admin_password}"
  #     script_path = "C:\\Users\\${var.admin_username}\\Documents\\customize_windows.ps1"
  #   }    
  # }
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
  virtual_machine_id = azurerm_virtual_machine.vm-linux[count.index].id
  lun     = "0"
  caching = var.data_disk_caching
}

# Windows vm
resource "azurerm_virtual_machine_data_disk_attachment" "data-disk2vm-windows" {
  count = var.data_disk && var.is_windows ? var.virtual_machine_instances : 0
  managed_disk_id = azurerm_managed_disk.vm-data-disk[count.index].id
  virtual_machine_id = azurerm_virtual_machine.vm-windows[count.index].id
  lun     = "0"
  caching = var.data_disk_caching
}

# JsonADDomainExtension extension
resource "azurerm_virtual_machine_extension" "vm-windows-joinext" {
  count               = var.join && var.is_windows ? var.virtual_machine_instances : 0
  name                = "${var.virtual_machine_names[count.index]}-joinext"
  virtual_machine_id = azurerm_virtual_machine.vm-windows[count.index].id

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
  virtual_machine_id = azurerm_virtual_machine.vm-windows[count.index].id

  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  # Funziona solo se il container custom-script-extension ha permessi di lettura da anonymous (access level container)
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

  # virtual_machine_name = "${azurerm_virtual_machine.vm-linux.*.name[count.index]}"
  virtual_machine_id = azurerm_virtual_machine.vm-linux[count.index].id
  publisher = "Microsoft.Azure.Extensions"
  type = "CustomScript"
  type_handler_version = "2.0"

  # Funziona solo se il container custom-script-extension ha permessi di lettura da anonymous (access level container)
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

# Availability set
resource "azurerm_availability_set" "vm-avset" {
  count                        = var.availability_set_enabled ? 1 : 0
  name                         = coalesce(var.availability_set_name, "${var.virtual_machine_names[0]}-avset")
  location                     = var.location
  resource_group_name          = var.resource_group
  platform_fault_domain_count  = var.availability_set_fault_domains
  platform_update_domain_count = var.availability_set_update_domains
  managed                      = var.availability_set_managed
  tags                         = var.tags
}

# Backup policy for the virtual machine
resource "azurerm_backup_protected_vm" "rs-protected-vm" {
  count               = var.backup_enabled ? var.virtual_machine_instances : 0
  resource_group_name = var.recovery_vault_resource_group
  recovery_vault_name = var.recovery_vault_name
  source_vm_id = var.is_windows ? azurerm_virtual_machine.vm-windows[count.index].id : azurerm_virtual_machine.vm-linux[count.index].id
  backup_policy_id = var.backup_policy_id
  
  # Commentata perché sembra non funzionare correttamente l'assegnazione dei tag per questa risorsa, cerca di assegnare i tag ad ogni giro! 
  # tags = "${var.tags}"
}

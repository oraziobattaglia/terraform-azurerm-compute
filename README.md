# terraform-azurerm-compute

## Deploys n vms, linux or windows, based on var.virtual_machine_instances and var.virtual_machine_names

This Terraform module deploys Virtual Machines in Azure, ideas from official module.

Repository and branches facts:
 - branch fix_old4 is used for releases v0.4.0 and later, this version use the old resource **azurerm_virtual_machine** **DEPRECATED**
 - branch fix_old5 is used for releases v0.5.1 and later, this version use the new resources **azurerm_linux_virtual_machine** and **azurerm_windows_virtual_machine**, **only one** data disk is allowed **DEPRECATED**
 - branch main is used for releases v0.6.1 and later, this version permit to have m data disks attached to n vms **CURRENT**

Deploys:
 - var.virtual_machine_instances number of linux vm or windows vm based on var.is_windows value
 - for each vm add a nic and a os disk
 - it's possible to add n data disk per vm based on data_disks list
 - if application security groups are in use it's possible to attach to the vm nic var.application_security_group_ids application security groups. It's a m to n relationship.
 - vms maybe backed up with the resource azurerm_backup_protected_vm
 - linux vm support a custom script extension to run a bash script after the deploy
 - windows vm support 2 custom script:
   - to run a powershell script after the deploy
   - to join the vm to an Active Directory domain

## Examples

```hcl

module "my_module" {
  source = "oraziobattaglia/compute/azurerm"

  location                        = var.location
  resource_group                  = var.resource_group
  virtual_machine_instances       = "2"
  virtual_machine_names           = ["my-vm-01", "my-vm-02"]
  subnet_id                       = var.subnet_id
  private_ip_address_allocation   = "Dynamic"
  enable_accelerated_networking   = false

  availability_set_enabled = true
  availability_set_id      = var.azurerm_availability_set_id
  
  # It's a list
  application_security_group_ids = var.application_security_group_ids

  is_windows           = false

  vm_size              = "Standard_D8s_v3"
  storage_account_type = "Premium_LRS"
  vm_os_publisher      = "canonical"
  vm_os_offer          = "0001-com-ubuntu-server-focal"
  vm_os_sku            = "20_04-lts-gen2"
  vm_os_version        = "latest"

  admin_username       = var.admin_username
  admin_password       = var.admin_password

  # Data disks
  data_disks = [
    {
      data_disk_sa_type = "Standard_LRS"
      data_disk_caching = "None"
      data_disk_size_gb = 25
      data_disk_lun     = 0
    },
    {
      data_disk_sa_type = "Standard_LRS"
      data_disk_caching = "None"
      data_disk_size_gb = 40
      data_disk_lun     = 1
    }
  ]

  # Boot diagnostics
  boot_diagnostics                 = true
  storage_account_boot_diagnostics = azurerm_storage_account.my_storage_account.primary_blob_endpoint

  # Backup variables
  backup_enabled = true
  recovery_vault_name           = var.recovery_vault_name
  recovery_vault_resource_group = var.recovery_vault_resource_group
  backup_policy_id              = var.backup_policy_id

  customize = true
  linux_cs_file_uri = "http://myserver.com/scripts/customize_linux.bash"
  linux_cs_command = "bash customize_linux.bash"
}

```

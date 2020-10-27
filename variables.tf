variable "location" {
  type        = string
  description = "Object location"
}

variable "resource_group" {
  type        = string
  description = "Object resource group"
}

variable "virtual_machine_instances" {
  type        = number
  description = "Number of Azure Virtual Machine to create"
  default     = 1
}

variable "virtual_machine_names" {
  type        = list(string)
  description = "A list of Azure Virtual Machine Names"
}

variable "network_security_group_id" {
  type        = string
  description = "Network security group attached to vm nic"
  default     = ""
}

variable "enable_accelerated_networking" {
  type        = bool
  description = "Should Accelerated Networking be enabled?"
  default     = false
}

variable "subnet_id" {
  type        = string
  description = "The subnet id where to create vms"
}

variable "private_ip_address_allocation" {
  type        = string
  description = "Ip allocation: Dynamic or Static"
}

variable "private_ip_addresses" {
  type        = list(string)
  description = "Private ip addresses for the virtual machines"
  default     = []
}

variable "public_ip_addresses" {
  type        = list(string)
  description = "Public ip addresses for the virtual machines"
  default     = []
}

variable "application_security_group_ids" {
  type        = list(string)
  description = "Application Security Group Ids to associate to nic"
  default     = []
}

variable "is_windows" {
  type        = bool
  description = "True for a Windows virtual machine"
}

variable "vm_size" {
  type        = string
  description = "Virtual machine size"
}

variable "license_type" {
  type        = string
  description = "Specifies the BYOL Type for this Virtual Machine"
  default     = "Windows_Server"
}

variable "delete_os_disk_on_termination" {
  type        = bool
  description = "Delete os disk on termination"
  default     = true
}

variable "delete_data_disk_on_termination" {
  type        = bool
  description = "Delete data disk on termination"
  default     = true
}

variable "vm_os_publisher" {
  type        = string
  description = "Vm os publisher"
}

variable "vm_os_offer" {
  type        = string
  description = "Vm os offer"
}

variable "vm_os_sku" {
  type        = string
  description = "Vm os sku"
}

variable "vm_os_version" {
  type        = string
  description = "Vm os version"
  default     = "latest"
}

variable "storage_account_type" {
  type        = string
  description = "Storage account type"
  default     = "Standard_LRS"
}

variable "os_create_option" {
  type        = string
  description = "Storage os disk create option"
  default     = "FromImage"
}

variable "use_custom_os_disk_size" {
  type        = bool
  description = "True to specify custom os data size"
  default     = false
}

variable "os_disk_size_gb" {
  type        = number
  description = "Storage os disk size"
  default     = 50
}

variable "data_disk" {
  type        = bool
  description = "True to add a data disk"
  default     = false
}

variable "data_sa_type" {
  description = "Data Disk Storage Account type"
  default     = "Standard_LRS"
}

variable "data_disk_caching" {
  description = "Data Disk caching type"
  default     = "None"
}

variable "data_disk_size_gb" {
  type        = number
  description = "Storage data disk size"
  default     = 0
}

variable "admin_username" {
  type        = string
  description = "Admin username"
}

variable "admin_password" {
  type        = string
  description = "Admin password"
}

variable "boot_diagnostics" {
  type        = bool
  description = "Boot diagnostics"
  default     = false
}

variable "storage_account_boot_diagnostics" {
  type        = string
  description = "Storage account boot diagnostics"
  default     = ""
}

variable "tags" {
  type        = any
  description = "Tags"
  default     = {}
}

# Backup variables
variable "backup_enabled" {
  type        = bool
  description = "True to set up backup configuration"
  default     = false
}

variable "recovery_vault_name" {
  type        = string
  description = "Recovery vault name"
  default     = ""
}

variable "recovery_vault_resource_group" {
  type        = string
  description = "Recovery vault resource group"
  default     = ""
}

variable "backup_policy_id" {
  type        = string
  description = "Backup policy id"
  default     = ""
}

# Availability_set variables
variable "availability_set_enabled" {
  type        = bool
  description = "True to enable availability set"
  default     = false
}

variable "availability_set_name" {
  type        = string
  description = "Name of the availability set"
  default     = ""
}

variable "availability_set_fault_domains" {
  type        = number
  description = "Number of availability set fault domains"
  default     = 2
}

variable "availability_set_update_domains" {
  type        = number
  description = "Number of availability set update domains"
  default     = 5
}

variable "availability_set_managed" {
  type        = bool
  description = "True for availability set managed"
  default     = true
}

# JsonADDomainExtension extension variables
variable "join" {
  type        = bool
  description = "True to join vm to domain"
  default     = false
}

variable "windows_domain_name" {
  type        = string
  description = "Name of the windows domain to join to"
  default     = ""
}

variable "windows_domain_username" {
  type        = string
  description = "Name of the user with domain join permission"
  default     = ""
}

variable "windows_domain_password" {
  type        = string
  description = "Password for the user with domain join permission"
  default     = ""
}

# Customization variables
variable "customize" {
  type        = bool
  description = "True to run customization script"
  default     = false
}

# Windows custom script extension variables
variable "windows_cs_file_uri" {
  type        = string
  description = "Windows custom script file URI"
  default     = ""
}

variable "windows_cs_command" {
  type        = string
  description = "Windows custom script command to execute"
  default     = "powershell -ExecutionPolicy Unrestricted -File customize_windows.ps1"
}

# Linux custom script extension variables
variable "linux_cs_file_uri" {
  type        = string
  description = "Linux custom script file URI"
  default     = ""
}

variable "linux_cs_command" {
  type        = string
  description = "Linux custom script command to execute"
  default     = "bash customize_linux.bash"
}

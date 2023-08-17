output "network_interface_private_ips" {
  description = "Private ip addresses of the vm nics"
  value       = azurerm_network_interface.nic.*.private_ip_address
}

output "network_interface_data" {
  description = "Array containing network interfaces data"
  value       = local.net_ints_data
}

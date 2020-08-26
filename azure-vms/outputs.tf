output "nodes" {
    value = azurerm_linux_virtual_machine.vm
}

output "ssh_key" {
    value = tls_private_key.global_key.private_key_pem
}
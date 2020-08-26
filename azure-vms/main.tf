#Create Resource group
resource "azurerm_resource_group" "rg" {
 name     = var.rg_name
 location = "Norway East"
}

#Create Vnet and subnet
resource "azurerm_virtual_network" "vnet" {
 name                = "ranchervnet"
 address_space       = ["10.0.0.0/23"]
 location            = azurerm_resource_group.rg.location
 resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
 name                 = "ranchersub"
 resource_group_name  = azurerm_resource_group.rg.name
 virtual_network_name = azurerm_virtual_network.vnet.name
 address_prefixes       = ["10.0.1.0/24"]
}

#Create Public IPs for VMs
resource "azurerm_public_ip" "vm_pip" {
  count               = var.number_vms
  name                = "pip_${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

#Create NSG to only allow SSH from your IP
resource "azurerm_network_security_group" "nsg" {
  name                = "ssh_nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
    
  security_rule {
    name                       = "SSH_Kubectl"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "131.115.50.0/23"
    destination_address_prefix = "*"
    }
}

#Create NICs for VM's
resource "azurerm_network_interface" "nic" {
 count               = var.number_vms
 name                = "nic_${count.index}"
 location            = azurerm_resource_group.rg.location
 resource_group_name = azurerm_resource_group.rg.name

 ip_configuration {
   name                          = "testConfiguration"
   subnet_id                     = azurerm_subnet.subnet.id
   private_ip_address_allocation = "dynamic"
   public_ip_address_id          = azurerm_public_ip.vm_pip[count.index].id
 }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "nsg_nic" {
  count                     = var.number_vms
  network_interface_id      = azurerm_network_interface.nic[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

#Create LB with PublicIP, LB rule etc..
resource "azurerm_public_ip" "pip" {
 name                         = "publicIPForLB"
 location                     = azurerm_resource_group.rg.location
 resource_group_name          = azurerm_resource_group.rg.name
 allocation_method            = "Static"
}

resource "azurerm_lb" "lb" {
 name                = "loadBalancer"
 location            = azurerm_resource_group.rg.location
 resource_group_name = azurerm_resource_group.rg.name

 frontend_ip_configuration {
   name                 = "publicIPAddress"
   public_ip_address_id = azurerm_public_ip.pip.id
 }
}

resource "azurerm_lb_backend_address_pool" "be_pool" {
 resource_group_name = azurerm_resource_group.rg.name
 loadbalancer_id     = azurerm_lb.lb.id
 name                = "BackEndAddressPool"
}

resource "azurerm_network_interface_backend_address_pool_association" "be_bind" {
  count                   = var.number_vms
  network_interface_id    = azurerm_network_interface.nic[count.index].id
  ip_configuration_name   = "testConfiguration"
  backend_address_pool_id = azurerm_lb_backend_address_pool.be_pool.id
}

resource "azurerm_lb_probe" "lb_probe" {
  resource_group_name = azurerm_resource_group.rg.name
  loadbalancer_id     = azurerm_lb.lb.id
  name                = "rancher-probe"
  port                = 443
}

resource "azurerm_lb_rule" "http_port_rule" {
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "publicIPAddress"
  probe_id                       = azurerm_lb_probe.lb_probe.id
  backend_address_pool_id        = azurerm_lb_backend_address_pool.be_pool.id
  }


#Create Disk for VM's
resource "azurerm_managed_disk" "disk" {
  count                = var.number_vms
  name                 = "datadisk_existing_${count.index}"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "50"
}

#Create SSH key to use for access to VM's
resource "tls_private_key" "global_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "ssh_private_key_pem" {
  filename          = "${path.module}/azure_demo"
  sensitive_content = tls_private_key.global_key.private_key_pem
  file_permission   = "0600"
}

resource "local_file" "ssh_public_key_openssh" {
  filename = "${path.module}/azure_demo.pub"
  content  = tls_private_key.global_key.public_key_openssh
}

#Create VMs and availability set
resource "azurerm_availability_set" "avset" {
  name                         = "avset"
  location                     = azurerm_resource_group.rg.location
  resource_group_name          = azurerm_resource_group.rg.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}

resource "azurerm_linux_virtual_machine" "vm" {
  count                 = var.number_vms
  name                  = "ranch_vm_${count.index}"
  computer_name         = "rancher${count.index}"
  admin_username        = "rancher"
  admin_password        = "Meetup2020!"
  location              = azurerm_resource_group.rg.location
  availability_set_id   = azurerm_availability_set.avset.id
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [element(azurerm_network_interface.nic.*.id, count.index)]
  size                  = "Standard_DS1_v2"

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    name                 = "myosdisk${count.index}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_ssh_key {
    username   = "rancher"
    public_key = tls_private_key.global_key.public_key_openssh
  }

  custom_data = base64encode(file("${path.module}/init.sh"))
  disable_password_authentication = true


 tags = {
   environment = "test"
 }
}
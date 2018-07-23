provider "azurerm" {}

variable "rgLocation" {
  default = "West US 2"
}

resource "azurerm_resource_group" "main" {
  name     = "ExampleRG"
  location = "${var.rgLocation}"
}

resource "azurerm_virtual_network" "main" {
  name                = "VirtualNetwork"
  address_space       = ["10.0.0.0/16"]
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"

}

resource "azurerm_network_security_group" "main" {
  name                = "inboundNSG"
  resource_group_name = "${azurerm_resource_group.main.name}"
  location            = "${azurerm_resource_group.main.location}"

  security_rule {
    name                       = "allow22"
    description                = "Allow Port 22"
    protocol                   = "tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    access                     = "allow"
    priority                   = "100"
    direction                  = "Inbound"
  }

}

resource "azurerm_subnet" "publicSubnet" {
  name                      = "public"
  virtual_network_name      = "${azurerm_virtual_network.main.name}"
  resource_group_name       = "${azurerm_resource_group.main.name}"
  address_prefix            = "10.0.1.0/24"
  network_security_group_id = "${azurerm_network_security_group.main.id}"
}

resource "azurerm_subnet" "privateSubnet" {
  name                 = "private"
  virtual_network_name = "${azurerm_virtual_network.main.name}"
  resource_group_name  = "${azurerm_resource_group.main.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_public_ip" "main" {
  name                         = "nginxPublicIP"
  resource_group_name          = "${azurerm_resource_group.main.name}"
  location                     = "${azurerm_resource_group.main.location}"
  public_ip_address_allocation = "Dynamic"
}

resource "azurerm_network_interface" "main" {
  name                = "nginxNic"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"

  ip_configuration {
    name                          = "nginxIpConfig"
    subnet_id                     = "${azurerm_subnet.publicSubnet.id}"
    public_ip_address_id          = "${azurerm_public_ip.main.id}"
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_managed_disk" "main" {
  name                 = "nginxManagedDisk"
  location             = "${azurerm_resource_group.main.location}"
  resource_group_name  = "${azurerm_resource_group.main.name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "10"
}

resource "azurerm_virtual_machine" "main" {
  name                  = "nginxVM"
  location              = "${azurerm_resource_group.main.location}"
  resource_group_name   = "${azurerm_resource_group.main.name}"
  network_interface_ids = ["${azurerm_network_interface.main.id}"]
  vm_size               = "${var.vmSize}"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "nginxOSDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name            = "${azurerm_managed_disk.main.name}"
    managed_disk_id = "${azurerm_managed_disk.main.id}"
    create_option   = "Attach"
    lun             = 1
    disk_size_gb    = "${azurerm_managed_disk.main.disk_size_gb}"
  }

  os_profile {
    computer_name  = "nginxWebOne"
    admin_username = "sshuser"
    admin_password = "espz@}5;#F(8fZPLF3"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

resource "azurerm_public_ip" "tfb-data" {
  name                    = "tfb-data-ip"
  resource_group_name     = "${azurerm_resource_group.main.name}"
  location                = "${azurerm_resource_group.main.location}"
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
}

resource "azurerm_network_security_group" "tfb-data" {
  name                = "tfb-data-nsg"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  
  security_rule {
    name                       = "default-allow-ssh"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "tfb-data" {
  name                          = "tfb-data-nic"
  location                      = "${azurerm_resource_group.main.location}"
  resource_group_name           = "${azurerm_resource_group.main.name}"
  network_security_group_id     = "${azurerm_network_security_group.tfb-data.id}"
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = "${azurerm_subnet.internal.id}"
    private_ip_address            = "${var.TFB_DATABASE_HOST}"
    private_ip_address_allocation = "Static"
    public_ip_address_id          = "${azurerm_public_ip.tfb-data.id}"
  }
}

resource "azurerm_virtual_machine" "tfb-data" {
  name                  = "tfb-data-vm"
  location              = "${azurerm_resource_group.main.location}"
  resource_group_name   = "${azurerm_resource_group.main.name}"
  network_interface_ids = ["${azurerm_network_interface.tfb-data.id}"]
  vm_size               = "Standard_D3_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "18.04.202004080"
  }
  storage_os_disk {
    name              = "tfb-data-osdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "tfb-data"
    admin_username = "${var.VM_ADMIN_USERNAME}"
  }
  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/${var.VM_ADMIN_USERNAME}/.ssh/authorized_keys"
      key_data = "${var.VM_PUBLIC_KEY}"
    }
  }

  provisioner "file" {
    connection {
      host        = "${azurerm_public_ip.tfb-data.ip_address}"
      type        = "ssh"
      user        = "${var.VM_ADMIN_USERNAME}"
      private_key = "${var.VM_PRIVATE_KEY}"
    }

    source      = "../script/tfb-vm-setup.sh"
    destination = "/home/${var.VM_ADMIN_USERNAME}/tfb-vm-setup.sh"
  }

  provisioner "remote-exec" {
    connection {
      host        = "${azurerm_public_ip.tfb-data.ip_address}"
      type        = "ssh"
      user        = "${var.VM_ADMIN_USERNAME}"
      private_key = "${var.VM_PRIVATE_KEY}"
    }

    inline = [
      "chmod +x /home/${var.VM_ADMIN_USERNAME}/tfb-vm-setup.sh",
      "/home/${var.VM_ADMIN_USERNAME}/tfb-vm-setup.sh",
    ]
  }
}

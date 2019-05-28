resource "azurerm_public_ip" "tfb-app" {
  name                    = "tfb-app-ip"
  resource_group_name     = "${azurerm_resource_group.main.name}"
  location                = "${azurerm_resource_group.main.location}"
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 30
}

resource "azurerm_network_security_group" "tfb-app" {
  name                = "tfb-app-nsg"
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

resource "azurerm_network_interface" "tfb-app" {
  name                          = "tfb-app-nic"
  location                      = "${azurerm_resource_group.main.location}"
  resource_group_name           = "${azurerm_resource_group.main.name}"
  network_security_group_id     = "${azurerm_network_security_group.tfb-app.id}"
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = "${azurerm_subnet.internal.id}"
    private_ip_address            = "${var.TFB_SERVER_HOST}"
    private_ip_address_allocation = "Static"
    public_ip_address_id          = "${azurerm_public_ip.tfb-app.id}"
  }
}

resource "azurerm_virtual_machine" "tfb-app" {
  name                  = "tfb-app-vm"
  location              = "${azurerm_resource_group.main.location}"
  resource_group_name   = "${azurerm_resource_group.main.name}"
  network_interface_ids = ["${azurerm_network_interface.tfb-app.id}"]
  vm_size               = "Standard_D3_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "tfb-app-osdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "tfb-app"
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
      type        = "ssh"
      user        = "${var.VM_ADMIN_USERNAME}"
      private_key = "${var.VM_PRIVATE_KEY}"
    }

    source      = "../script"
    destination = "/home/${var.VM_ADMIN_USERNAME}"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "${var.VM_ADMIN_USERNAME}"
      private_key = "${var.VM_PRIVATE_KEY}"
    }

    inline = [
      "chmod +x /home/${var.VM_ADMIN_USERNAME}/script/*",
      "/home/${var.VM_ADMIN_USERNAME}/script/tfb-vm-setup.sh",
      "sleep 10",
      # Set up vars
      #"export AZURE_CLIENT_ID=${var.AZURE_CLIENT_ID}",
      #"export AZURE_CLIENT_SECRET=${var.AZURE_CLIENT_SECRET}",
      #"export AZURE_STORAGE_ACCOUNT_NAME=${var.AZURE_STORAGE_ACCOUNT_NAME}",
      #"export AZURE_STORAGE_CONTAINER_NAME=${var.AZURE_STORAGE_CONTAINER_NAME}",
      #"export AZURE_STORAGE_RESOURCE_GROUP_NAME=${var.AZURE_STORAGE_RESOURCE_GROUP_NAME}",
      "export AZURE_TEARDOWN_TRIGGER_URL='${var.AZURE_TEARDOWN_TRIGGER_URL}'",
      #"export AZURE_TENANT_ID=${var.AZURE_TENANT_ID}",
      "export TFB_SERVER_HOST=${var.TFB_SERVER_HOST}",
      "export TFB_DATABASE_HOST=${var.TFB_DATABASE_HOST}",
      "export TFB_CLIENT_HOST=${var.TFB_CLIENT_HOST}",
      "export TFB_COMMAND=${var.TFB_COMMAND}",
      "export TFB_RESULTS_NAME=${var.TFB_RESULTS_NAME}",
      "export TFB_RESULTS_ENVIRONMENT=${var.TFB_RESULTS_ENVIRONMENT}",
      "export TFB_UPLOAD_URI='${var.TFB_UPLOAD_URI}'",
      "export VM_ADMIN_USERNAME=${var.VM_ADMIN_USERNAME}",
      "sudo mkdir /mnt/tfb",
      "sudo chown ${var.VM_ADMIN_USERNAME} /mnt/tfb",
      "git clone https://github.com/TechEmpower/FrameworkBenchmarks.git /mnt/tfb/FrameworkBenchmarks",
      "git -C /mnt/tfb/FrameworkBenchmarks checkout ${var.TFB_BRANCH_OR_COMMIT}",
      "nohup bash /home/${var.VM_ADMIN_USERNAME}/script/tfb-post-process.sh &",
      # Sleep to ensure the previous nohup command is executed
      "sleep 10",
    ]
  }

  depends_on = ["azurerm_virtual_machine.tfb-data", "azurerm_virtual_machine.tfb-load"]
}

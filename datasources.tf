data "azurerm_resource_group" "example" {
  name = "${var.prefix}-resources"
}

data "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  resource_group_name = data.azurerm_resource_group.example.name
}

data "azurerm_subnet" "internal" {
  name                 = "internal"
  virtual_network_name = data.azurerm_virtual_network.main.name
  resource_group_name  = data.azurerm_resource_group.example.name
}

data "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  resource_group_name = data.azurerm_resource_group.example.name
}

resource "azurerm_public_ip" "example" {
  name                = "${var.prefix}-public-ip"
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name
  allocation_method   = "Static"
}

data "azurerm_virtual_machine" "main" {
  name                = "${var.prefix}-vm"
  resource_group_name = data.azurerm_resource_group.example.name
}

resource "terraform_data" "file_transfer" {
  triggers_replace = {
    file_hash     = filesha256("${path.module}/index.html")
    vm_id         = data.azurerm_virtual_machine.main.id
    force_run_now = timestamp()
  }

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "testadmin"
      password = "Password1234!"
      host     = azurerm_public_ip.example.ip_address
    }
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y nginx"

    ]
  }

  provisioner "file" {
    source      = "./index.html"
    destination = "/var/www/html/index.html"

  }

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "testadmin"
      password = "Password1234!"
      host     = azurerm_public_ip.example.ip_address
    }
    inline = [
      "sudo systemctl restart nginx"
    ]
  }
  connection {
    type     = "ssh"
    user     = "testadmin"
    password = "Password1234!"
    host     = azurerm_public_ip.example.ip_address
  }
}

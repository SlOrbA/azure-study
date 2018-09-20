resource "azurerm_resource_group" "app" {
  name     = "W1-E6-App"
  location = "North Europe"
}

resource "azurerm_virtual_network" "app" {
  name                 = "W1-E6-App-vnet"
  address_space        = ["10.0.0.0/16"]
  location             = "${azurerm_resource_group.app.location}"
  resource_group_name = "${azurerm_resource_group.app.name}"
}

resource "azurerm_subnet" "app" {
  name                 = "W1-E6-App-subnet"
  resource_group_name = "${azurerm_resource_group.app.name}"
  virtual_network_name = "${azurerm_virtual_network.app.name}"
  address_prefix       = "10.0.1.0/24"
}

resource "azurerm_network_security_group" "app" {
  name                = "W1-E6-App-NSG"
  location            = "${azurerm_resource_group.app.location}"
  resource_group_name = "${azurerm_resource_group.app.name}"
}

resource "azurerm_network_security_rule" "app_http" {
  name                        = "AllowHTTP"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.app.name}"
  network_security_group_name = "${azurerm_network_security_group.app.name}"
}

resource "azurerm_network_security_rule" "app_https" {
  name                        = "AllowHTTPS"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.app.name}"
  network_security_group_name = "${azurerm_network_security_group.app.name}"
}

resource "azurerm_storage_account" "app" {
  name                     = "w1e6appstrg"
  resource_group_name      = "${azurerm_resource_group.app.name}"
  location                 = "${azurerm_resource_group.app.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "app" {
  name                  = "w1e6appvhds"
  resource_group_name   = "${azurerm_resource_group.app.name}"
  storage_account_name  = "${azurerm_storage_account.app.name}"
  container_access_type = "private"
}

resource "azurerm_virtual_machine_scale_set" "app" {
  name                = "W1-E6-App-VM-scale-set"
  location            = "${azurerm_resource_group.app.location}"
  resource_group_name = "${azurerm_resource_group.app.name}"
  upgrade_policy_mode = "Manual"

  sku {
    name     = "Standard_A1"
    tier     = "Standard"
    capacity = 1
  }

  os_profile {
    computer_name_prefix = "W1-E6-App-VM"
    admin_username       = "myadmin"
    admin_password       = "KPaszxcvasdfasdf"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/myadmin/.ssh/authorized_keys"
      key_data = "${file("~/.ssh/authorized_keys")}"
    }
  }

  network_profile {
    name    = "NetworkProfile"
    primary = true

    network_security_group_id = "${azurerm_network_security_group.app.id}"

    ip_configuration {
      name      = "IPConfiguration"
      subnet_id = "${azurerm_subnet.app.id}"
    }
  }

  storage_profile_os_disk {
    name           = "osDiskProfile"
    caching        = "ReadWrite"
    create_option  = "FromImage"
    vhd_containers = ["${azurerm_storage_account.app.primary_blob_endpoint}${azurerm_storage_container.app.name}"]
  }

  storage_profile_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}

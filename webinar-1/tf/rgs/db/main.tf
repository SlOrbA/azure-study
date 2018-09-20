resource "azurerm_resource_group" "db" {
  name     = "W1-E6-DB"
  location = "North Europe"
}

resource "azurerm_virtual_network" "db" {
  name                 = "W1-E6-DB-vnet"
  address_space        = ["10.0.0.0/16"]
  location             = "${azurerm_resource_group.db.location}"
  resource_group_name = "${azurerm_resource_group.db.name}"
}

resource "azurerm_subnet" "db" {
  name                 = "W1-E6-DB-subnet"
  resource_group_name = "${azurerm_resource_group.db.name}"
  virtual_network_name = "${azurerm_virtual_network.db.name}"
  address_prefix       = "10.0.1.0/24"
}

resource "azurerm_network_security_group" "db" {
  name                = "W1-E6-DB-NSG"
  location            = "${azurerm_resource_group.db.location}"
  resource_group_name = "${azurerm_resource_group.db.name}"
}

resource "azurerm_network_security_rule" "db_sql_in" {
  name                        = "AllowSQL"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "1433"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.db.name}"
  network_security_group_name = "${azurerm_network_security_group.db.name}"
}

resource "azurerm_network_security_rule" "db_deny_in" {
  name                        = "DenyAllInBound"
  priority                    = 4096
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.db.name}"
  network_security_group_name = "${azurerm_network_security_group.db.name}"
}

resource "azurerm_storage_account" "db" {
  name                     = "w1e6dbstrg"
  resource_group_name      = "${azurerm_resource_group.db.name}"
  location                 = "${azurerm_resource_group.db.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "db" {
  name                  = "w1e6dbvhds"
  resource_group_name   = "${azurerm_resource_group.db.name}"
  storage_account_name  = "${azurerm_storage_account.db.name}"
  container_access_type = "private"
}

resource "azurerm_virtual_machine_scale_set" "db" {
  name                = "W1-E6-DB-VM-scale-set"
  location            = "${azurerm_resource_group.db.location}"
  resource_group_name = "${azurerm_resource_group.db.name}"
  upgrade_policy_mode = "Manual"

  sku {
    name     = "Standard_A1"
    tier     = "Standard"
    capacity = 1
  }

  os_profile {
    computer_name_prefix = "W1-E6-DB-VM"
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

    network_security_group_id = "${azurerm_network_security_group.db.id}"

    ip_configuration {
      name      = "IPConfiguration"
      subnet_id = "${azurerm_subnet.db.id}"
    }
  }

  storage_profile_os_disk {
    name           = "osDiskProfile"
    caching        = "ReadWrite"
    create_option  = "FromImage"
    vhd_containers = ["${azurerm_storage_account.db.primary_blob_endpoint}${azurerm_storage_container.db.name}"]
  }

  storage_profile_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}

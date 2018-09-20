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

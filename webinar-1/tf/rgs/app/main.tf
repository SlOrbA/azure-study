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

resource "azurerm_availability_set" "app" {
  name     = "W1-E6-App-avset"
  location = "${azurerm_resource_group.app.location}"
  resource_group_name = "${azurerm_resource_group.app.name}"
}

resource "azurerm_network_interface" "app" {
  name = "W1-E6-App-nic"
  location = "${azurerm_resource_group.app.location}"
  resource_group_name = "${azurerm_resource_group.app.name}"

  ip_configuration {
    name                          = "AppConfiguration"
    subnet_id                     = "${azurerm_subnet.app.id}"
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_virtual_machine" "app" {
  name = "W1-E6-App-vm"
  location = "${azurerm_resource_group.app.location}"
  resource_group_name = "${azurerm_resource_group.app.name}"
  network_interface_ids = ["${azurerm_network_interface.app.id}"]
  vm_size = "Standard_A1_v2"

  storage_image_reference {
    publisher = "Microsoft"
    offer = ""
    sku = ""
    version = "latesti"
  }

  storage_os_disk {
    name = "AppOSDisk1"
    caching = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name = "appserver"
    admin_username = "testi"
    admin_password = "fs,lwe,ölv,lwe"
  }

  os_profile_windows_config {
    provision_vm_agent = true
  }
}

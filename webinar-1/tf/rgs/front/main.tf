resource "azurerm_resource_group" "front" {
  name     = "W1-E6-AppGW"
  location = "North Europe"
}

resource "azurerm_virtual_network" "front" {
  name                = "W1-E6-AppGW-vnet"
  resource_group_name = "${azurerm_resource_group.front.name}"
  address_space       = ["10.254.0.0/16"]
  location            = "${azurerm_resource_group.front.location}"
}

resource "azurerm_subnet" "front_sub1" {
  name                 = "W1-E6-AppGW-subnet-1"
  resource_group_name  = "${azurerm_resource_group.front.name}"
  virtual_network_name = "${azurerm_virtual_network.front.name}"
  address_prefix       = "10.254.0.0/24"
}

resource "azurerm_subnet" "front_sub2" {
  name                 = "W1-E6-AppGW-subnet-2"
  resource_group_name  = "${azurerm_resource_group.front.name}"
  virtual_network_name = "${azurerm_virtual_network.front.name}"
  address_prefix       = "10.254.2.0/24"
}

resource "azurerm_public_ip" "front" {
  name                         = "W1-E6-AppGW-PublicIP"
  location                     = "${azurerm_resource_group.front.location}"
  resource_group_name          = "${azurerm_resource_group.front.name}"
  public_ip_address_allocation = "dynamic"
}

resource "azurerm_application_gateway" "front" {
  name                = "W1-E6-AppGW"
  resource_group_name = "${azurerm_resource_group.front.name}"
  location            = "${azurerm_resource_group.front.location}"

  sku {
    name           = "Standard_Small"
    tier           = "Standard"
    capacity       = 2
  }

  gateway_ip_configuration {
    name         = "W1-E6-AppGW-ip-configuration"
    subnet_id    = "${azurerm_virtual_network.front.id}/subnets/${azurerm_subnet.front_sub1.name}"
  }

  frontend_port {
    name         = "${azurerm_virtual_network.front.name}-feport"
    port         = 80
  }

  frontend_ip_configuration {
    name         = "${azurerm_virtual_network.front.name}-feip"
    public_ip_address_id = "${azurerm_public_ip.front.id}"
  }

  backend_address_pool {
    name = "${azurerm_virtual_network.front.name}-beap"
  }

  backend_http_settings {
    name                  = "${azurerm_virtual_network.front.name}-be-htst"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 1
  }

  http_listener {
    name                            = "${azurerm_virtual_network.front.name}-httplstn"
    frontend_ip_configuration_name  = "${azurerm_virtual_network.front.name}-feip"
    frontend_port_name              = "${azurerm_virtual_network.front.name}-feport"
    protocol                        = "Http"
  }

  request_routing_rule {
    name                       = "${azurerm_virtual_network.front.name}-rqrt"
    rule_type                  = "Basic"
    http_listener_name         = "${azurerm_virtual_network.front.name}-httplstn"
    backend_address_pool_name  = "${azurerm_virtual_network.front.name}-beap"
    backend_http_settings_name = "${azurerm_virtual_network.front.name}-be-htst"
  }

  // Path-based routing example
  http_listener {
    name                           = "${azurerm_virtual_network.front.name}-httplstn-pbr.contoso.com"
    host_name                      = "pbr.contoso.com"
    frontend_ip_configuration_name = "${azurerm_virtual_network.front.name}-feip"
    frontend_port_name             = "${azurerm_virtual_network.front.name}-feport"
    protocol                       = "Http"
  }

  backend_address_pool {
    name = "${azurerm_virtual_network.front.name}-beap-fallback"
  }
  backend_address_pool {
    name = "${azurerm_virtual_network.front.name}-beap-first"
  }
  backend_address_pool {
    name = "${azurerm_virtual_network.front.name}-beap-second"
  }

  request_routing_rule {
    name               = "${azurerm_virtual_network.front.name}-rqrt"
    rule_type          = "PathBasedRouting"
    http_listener_name = "${azurerm_virtual_network.front.name}-httplstn-pbr.contoso.com"
    url_path_map_name  = "pbr.contoso.com"
  }

  url_path_map {
    name = "pbr.contoso.com"
    default_backend_address_pool_name = "${azurerm_virtual_network.front.name}-beap-fallback"
    default_backend_http_settings_name = "${azurerm_virtual_network.front.name}-be-htst"

    path_rule {
      name = "pbr.contoso.com_first"
      paths = ["/first/*"]
      backend_address_pool_name = "${local.awg_clusters_name}-beap-first"
      backend_http_settings_name = "${local.awg_clusters_name}-be-htst"
    }
    path_rule {
      name = "pbr.contoso.com_second"
      paths = ["/second/*"]
      backend_address_pool_name = "${local.awg_clusters_name}-beap-second"
      backend_http_settings_name = "${local.awg_clusters_name}-be-htst"
    }
  }
}

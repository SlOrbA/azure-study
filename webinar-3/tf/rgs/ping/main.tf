# Create a resource group Ping
resource "azurerm_resource_group" "ping" {
  name     = "hlan-ping"
  location = "${var.location}"
  tags {
    environment = "${var.env}"
  }
}

resource "azurerm_storage_account" "ping" {
  name                     = "hlanping"
  resource_group_name      = "${azurerm_resource_group.ping.name}"
  location                 = "${azurerm_resource_group.ping.location}"
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  access_tier              = "Cool"
  tags {
    environment = "${var.env}"
  }
}

resource "azurerm_app_service_plan" "ping" {
  name                = "hlanping"
  location            = "${azurerm_resource_group.ping.location}"
  resource_group_name = "${azurerm_resource_group.ping.name}"
  kind                = "FunctionApp"

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_function_app" "ping" {
  name                      = "hlanping"
  location                  = "${azurerm_resource_group.ping.location}"
  resource_group_name       = "${azurerm_resource_group.ping.name}"
  app_service_plan_id       = "${azurerm_app_service_plan.ping.id}"
  storage_connection_string = "${azurerm_storage_account.ping.primary_connection_string}"

  app_settings {
    "APPINSIGHTS_INSTRUMENTATIONKEY" = "${azurerm_application_insights.ping.instrumentation_key}"
  }

  provisioner "local-exec" {
    command     = "ls | grep ${self.name} | xargs rm -rf "
    when        = "destroy"
    working_dir = ".repos"
  }

  provisioner "local-exec" {
    command     = "git clone https://github.com/Azure-Samples/functions-quickstart.git ${self.name}"
    working_dir = ".repos"

    environment {
      repo = "git@github.com:Azure-Samples/functions-quickstart.git"
    }
  }
  provisioner "local-exec" {
    command     = "git remote add az-${lower(var.env)} https://\\${self.site_credential.0.username}:${self.site_credential.0.password}@${self.name}.scm.azurewebsites.net:443/${self.name}.git"
    working_dir = ".repos/${self.name}"
  }
  provisioner "local-exec" {
    command     = "git push az-${lower(var.env)}"
    working_dir = ".repos/${self.name}"
  }


}

resource "azurerm_application_insights" "ping" {
  name                = "hlanping"
  location            = "${azurerm_resource_group.ping.location}"
  resource_group_name = "${azurerm_resource_group.ping.name}"
  application_type    = "Web"
}

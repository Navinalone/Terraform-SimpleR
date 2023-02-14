
# Define Terraform provider
terraform {
  required_version = ">= 0.12"
}
# Configure the Azure provider
provider "azurerm" { 
  environment = "public"
  version = ">= 2.0.0"
  features {}  
}
resource "azurerm_resource_group" "example" {
  name     = "test-RG"
  location = var.location

  tags = {
    "name" = "test-rg"
  }
}
##########public ip #########
resource "azurerm_public_ip" "public_ip" {
  name                = "vm_public_ip"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  allocation_method   = "Dynamic"
}

####### Creating virtuval network
resource "azurerm_network_security_group" "example-nsg" {
  name                = "example-security-group-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
    security_rule {
    name                       = "allow_ssh_sg"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}


resource "azurerm_virtual_network" "example-vnet" {
  name                = "example-test-vnet1"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]


  tags = {
    environment = "test-env"
  }
}

######## Creating subnet

resource "azurerm_subnet" "example1" {
  name                 = "subnet1"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example-vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}
resource "azurerm_subnet" "example2" {
  name                 = "subnet2"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example-vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}
# Creating NIC card
resource "azurerm_network_interface" "example" {
  name                = "example-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }
}
resource "azurerm_network_interface_security_group_association" "association" {
  network_interface_id      = azurerm_network_interface.example.id
  network_security_group_id = azurerm_network_security_group.example-nsg.id
}
# Creating windows virtual machine 
resource "azurerm_windows_virtual_machine" "example" {
  name                = "example-machine"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234"
  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}

# creating keyvault 
resource "azurerm_key_vault" "example" {
  name                        = "test-nv-kv8"
  location                    = azurerm_resource_group.example.location
  resource_group_name         = azurerm_resource_group.example.name
  enabled_for_disk_encryption = true
  tenant_id                   = "c17bc0da-e1f8-412c-aa28-92e88ce37af9"
  # soft_delete_enabled         = true
  # purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = "c17bc0da-e1f8-412c-aa28-92e88ce37af9"
    object_id = "5c6d5590-efd0-4c9c-bbe3-71a19bd1d9fb"

    key_permissions = [
      "get",
    ]

    secret_permissions = [
      "get",
    ]

    storage_permissions = [
      "get",
    ]
  }

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }

  tags = {
    environment = "Testing"
  }
}

## creating stoarge account 

resource "azurerm_storage_account" "example" {
  name                     = "testnavin1"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "test-stoarge-account"
  }
}
## creating stoarge account  container###########
resource "azurerm_storage_container" "example" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "private"
}
## creating stoarge account  container############
resource "azurerm_storage_container" "example2" {
  name                  = "backend"
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "private"
}
############## creating stoarge account container###
resource "azurerm_storage_container" "example1" {
  name                  = "test1"
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "private"
}
#############fileshare creation ######################
resource "azurerm_storage_share" "example" {
  name                 = "navintest"
  storage_account_name = azurerm_storage_account.example.name
  quota                = 50
}
resource "azurerm_storage_share" "example1" {
  name                 = "navinprd"
  storage_account_name = azurerm_storage_account.example.name
  quota                = 50
}
################# Creating log analytic woekspace ########
# resource "azurerm_log_analytics_workspace" "example" {
#   name                = "nvn-test-log-analytics"
#   location            = azurerm_resource_group.example.location
#   resource_group_name = azurerm_resource_group.example.name
#   sku                 = "Free"
#   #retention_in_days   = 30
# }
# ############ application insights ########
# resource "azurerm_application_insights" "example" {
#   name                = "tf-test-appinsights"
#   location            = azurerm_resource_group.example.location
#   resource_group_name = azurerm_resource_group.example.name
#   workspace_id        = azurerm_log_analytics_workspace.example.id
#   application_type    = "web"
# }

# output "instrumentation_key" {
#   value = azurerm_application_insights.example.instrumentation_key
# }

# output "app_id" {
#   value = azurerm_application_insights.example.app_id
# }

######### sql server ##########
resource "azurerm_sql_server" "example" {
  name                         = "ms-sql-server-test-svr"
  resource_group_name          = azurerm_resource_group.example.name
  location                     = azurerm_resource_group.example.location
  version                      = "12.0"
  administrator_login          = "mradministrator"
  administrator_login_password = "thisIsDog11"

  tags = {
    environment = "testproduction"
  }
}
resource "azurerm_sql_elasticpool" "example" {
  name                = "test-sqlpool"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  server_name         = azurerm_sql_server.example.name
  edition             = "Basic"
  dtu                 = 50
  # db_dtu_min          = 0
  # db_dtu_max          = 5
  # pool_size           = 5000
}
resource "azurerm_sql_database" "example" {
  name                = "myexamplesqldatabase"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  server_name         = azurerm_sql_server.example.name

  # extended_auditing_policy {
  #   storage_endpoint                        = azurerm_storage_account.example.primary_blob_endpoint
  #   storage_account_access_key              = azurerm_storage_account.example.primary_access_key
  #   storage_account_access_key_is_secondary = true
  #   retention_in_days                       = 6
  # }

  tags = {
    environment = "fortest production"
  }
}
################### creating service bus namspace and ques ###############
resource "azurerm_servicebus_namespace" "example" {
  name                = "nvn-test-bus"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "Standard"

  tags = {
    source = "terraform"
  }
}

resource "azurerm_servicebus_queue" "example" {
  name         = "nvn_test_queue"
  namespace_id = azurerm_servicebus_namespace.example.id

  enable_partitioning = true
}
resource "azurerm_servicebus_queue" "example1" {
  name         = "output_queue"
  namespace_id = azurerm_servicebus_namespace.example.id

  enable_partitioning = true
}
resource "azurerm_servicebus_queue" "example2" {
  name         = "input_queue"
  namespace_id = azurerm_servicebus_namespace.example.id

  enable_partitioning = true
}

################################

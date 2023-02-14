terraform {
  backend "azurerm" {
    resource_group_name  = "test-RG"
    storage_account_name = "testnavin1"
    container_name       = "tfstate"
    key                  = "test.terraform.tfstate"
    access_key           = ""
  }
}

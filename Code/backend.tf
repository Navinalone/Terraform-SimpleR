terraform {
  backend "azurerm" {
    resource_group_name  = "test-RG"
    storage_account_name = "testnavin1"
    container_name       = "tfstate"
    key                  = "test.terraform.tfstate"
    access_key           = "4rE9Jc6d/dPzIOQsDJPmL69pZ4OM3vRNlvrAUKOGLoJOfbDLPjIMYQrHs4svDATtP9rwCx4K7VO3+AStIctCCw=="
  }
}
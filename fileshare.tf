
resource "azurerm_storage_account" "acafileshare" {
  name                     = var.storage-account
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "dfy"{
  name                  = var.storage-account-container
  storage_account_name  = azurerm_storage_account.acafileshare.name
  container_access_type = "private"
}


module "nginx_fileshare" {
  source              = "./fileshare_module"
  storage_account_name = azurerm_storage_account.acafileshare.name
  local_mount_dir      = "mountfiles/nginx"
  share_name           = "nginx"
}

module "sandbox_fileshare" {
  source              = "./fileshare_module"
  storage_account_name = azurerm_storage_account.acafileshare.name
  local_mount_dir      = "mountfiles/sandbox"
  share_name           = "sandbox"
}

module "ssrf_proxy_fileshare" {
  source              = "./fileshare_module"
  storage_account_name = azurerm_storage_account.acafileshare.name
  local_mount_dir      = "mountfiles/ssrfproxy"
  share_name           = "ssrfproxy"
}



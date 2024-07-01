# resource "azurerm_resource_group" "postgres" {
#   name     = "rg-${var.region}-postgres"
#   location = var.region
# }

resource "azurerm_private_dns_zone" "postgres" {
  name                = "private.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = azurerm_postgresql_flexible_server.postgres.name
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  resource_group_name   = azurerm_resource_group.rg.name
}


resource "azurerm_postgresql_flexible_server" "postgres" {
  name                          = var.psql-flexible
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  version                       = "16"
  delegated_subnet_id           = azurerm_subnet.postgressubnet.id
  private_dns_zone_id           = azurerm_private_dns_zone.postgres.id
  public_network_access_enabled = false
  administrator_login           = var.pgsql-user
  administrator_password        = "#QWEASDasdqwe"
  zone                          = "1"

  storage_mb   = 32768
  storage_tier = "P30"

  sku_name   = "B_Standard_B1ms"
  # depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]
}

resource "azurerm_postgresql_flexible_server_database" "difypgsqldb" {
  name      = "difypgsqldb"
  server_id = azurerm_postgresql_flexible_server.postgres.id
  collation = "en_US.utf8"
  charset   = "utf8"

  # prevent the possibility of accidental data loss
}

resource "azurerm_postgresql_flexible_server_database" "pgvector" {
  name      = "pgvector"
  server_id = azurerm_postgresql_flexible_server.postgres.id
  collation = "en_US.utf8"
  charset   = "utf8"

  # prevent the possibility of accidental data loss
#   lifecycle {
#     prevent_destroy = true
#   }
}

resource "azurerm_postgresql_flexible_server_configuration" "extension" {
  name      = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.postgres.id
  value     = "vector,uuid-ossp"
}

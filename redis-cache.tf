#create resource group for redis cache
# resource "azurerm_resource_group" "redis" {
#   name     = "rg-${var.region}-redis"
#   location = var.region
# }

#create azure redis cache with vnet integration
resource "azurerm_redis_cache" "redis" {
  count               = var.is_aca_enabled ? 1 : 0
  name                = "${var.redis}${random_id.rg_name.hex}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  capacity            = 0
  family              = "C"
  sku_name            = "Standard"
  enable_non_ssl_port = true
  minimum_tls_version = "1.2"

  public_network_access_enabled = false
  redis_version       = "6"
  
  # subnet_id           = azurerm_subnet.redissubnet.id
  # zones               = [ "1" ]

  redis_configuration {
    maxmemory_policy = "allkeys-lru"
  }
}

resource "azurerm_private_endpoint" "pe-redis" {
  count               = var.is_aca_enabled ? 1 : 0
  name                = "pe-redis"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.privatelinksubnet.id

  private_service_connection {
    name                           = "psc-redis"
    # private_connection_resource_id = azurerm_redis_cache.redis[0].id
    private_connection_resource_id = length(azurerm_redis_cache.redis) > 0 ? azurerm_redis_cache.redis[0].id : ""
    subresource_names              = ["redisCache"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdz-stor"
    private_dns_zone_ids = [azurerm_private_dns_zone.redis.id]
  }
}

resource "azurerm_private_dns_zone" "redis" {
  name                = "privatelink.redis.cache.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "redis-vnet" {
  name                  = "redis-dns-link"

  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.redis.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

output "redis_cache_hostname" {
  # value = azurerm_redis_cache.redis[0].hostname
  value = var.is_aca_enabled ? azurerm_redis_cache.redis[0].hostname : ""
}

output "redis_cache_key" {
  # value = azurerm_redis_cache.redis[0].primary_access_key
  value = var.is_aca_enabled ? azurerm_redis_cache.redis[0].primary_access_key : ""
  sensitive = true
}


resource "azurerm_log_analytics_workspace" "aca-loga" {
  name                = var.aca-loga
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}


resource "azurerm_container_app_environment" "dify-aca-env" {
  name                       = var.aca-env
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.aca-loga.id
  infrastructure_subnet_id = azurerm_subnet.acasubnet.id
  workload_profile  {
    name = "Consumption"
    workload_profile_type = "Consumption"
  }

  depends_on = [ 
    azurerm_redis_cache.redis,
    azurerm_postgresql_flexible_server.postgres
   ]
}

resource "azurerm_container_app_environment_storage" "nginxfileshare" {
  name                         = "nginxshare"
  container_app_environment_id = azurerm_container_app_environment.dify-aca-env.id
  account_name                 = azurerm_storage_account.acafileshare.name
  # share_name = 
  share_name                   = module.nginx_fileshare.share_name
  access_key                   = azurerm_storage_account.acafileshare.primary_access_key
  access_mode                  = "ReadWrite"
}

resource "azurerm_container_app_environment_certificate" "difycerts" {
  name                         = "difycerts"
  container_app_environment_id = azurerm_container_app_environment.dify-aca-env.id
  certificate_blob_base64 = filebase64(var.aca-cert-path)
  certificate_password = var.aca-cert-password
}

resource "azurerm_container_app" "nginx" {
  name                         = "nginx"
  container_app_environment_id = azurerm_container_app_environment.dify-aca-env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  template {
    http_scale_rule {
      name = "nginx"
      concurrent_requests = "10"
    }
    max_replicas = 10
    min_replicas = 0
    container {
      name   = "nginx"
      image  = "nginx:latest"
      cpu    = 0.5
      memory = "1Gi"
      volume_mounts { 
        name = "nginxconf"
        path = "/etc/nginx"
      }
    }
    volume {
      name = "nginxconf"
      storage_type = "AzureFile"
      storage_name = azurerm_container_app_environment_storage.nginxfileshare.name
    }
  }
  ingress {
    target_port = 80
    # exposed_port = 443
    external_enabled = true
    traffic_weight {
      # weight = 100
      percentage = 100
      latest_revision = true
    }
    transport = "auto"
    
    custom_domain {
      name = var.aca-dify-customer-domain
      certificate_id = azurerm_container_app_environment_certificate.difycerts.id
    }
  }
}

resource "azurerm_container_app_environment_storage" "ssrfproxyfileshare" {
  name                         = "ssrfproxyfileshare"
  container_app_environment_id = azurerm_container_app_environment.dify-aca-env.id
  account_name                 = azurerm_storage_account.acafileshare.name
  # share_name = 
  share_name                   = module.ssrf_proxy_fileshare.share_name
  access_key                   = azurerm_storage_account.acafileshare.primary_access_key
  access_mode                  = "ReadWrite"
}

resource "azurerm_container_app" "ssrfproxy" {
  name                         = "ssrfproxy"
  container_app_environment_id = azurerm_container_app_environment.dify-aca-env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  template {
    tcp_scale_rule {
      name = "ssrfproxy"
      concurrent_requests = "10"
    }
    max_replicas = 10
    min_replicas = 0
    container {
      name   = "ssrfproxy"
      image  = "ubuntu/squid:latest"
      cpu    = 0.5
      memory = "1Gi"
      volume_mounts { 
        name = "ssrfproxy"
        path = "/etc/squid"
      }
    }
    volume {
      name = "ssrfproxy"
      storage_type = "AzureFile"
      storage_name = azurerm_container_app_environment_storage.ssrfproxyfileshare.name
    }
  }
  ingress {
    target_port = 3128
    # exposed_port = 3128
    external_enabled = false
    traffic_weight {
      # weight = 100
      percentage = 100
      latest_revision = true
    }
    transport = "auto"
  }
}


resource "azurerm_container_app_environment_storage" "sandboxfileshare" {
  name                         = "sandbox"
  container_app_environment_id = azurerm_container_app_environment.dify-aca-env.id
  account_name                 = azurerm_storage_account.acafileshare.name
  # share_name = 
  share_name                   = module.sandbox_fileshare.share_name
  access_key                   = azurerm_storage_account.acafileshare.primary_access_key
  access_mode                  = "ReadWrite"
}

resource "azurerm_container_app" "sandbox" {
  name                         = "sandbox"
  container_app_environment_id = azurerm_container_app_environment.dify-aca-env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  template {
    tcp_scale_rule {
      name = "sandbox"
      concurrent_requests = "10"
    }
    max_replicas = 10
    min_replicas = 0
    container {
      name   = "langgenius"
      image  = var.dify-sandbox-image
      cpu    = 0.5
      memory = "1Gi"
      env {
        name  = "API_KEY"
        value = "dify-sandbox"
      }
      env {
        name  = "GIN_MODE"
        value = "release"
      }
      env {
        name  = "WORKER_TIMEOUT"
        value = "15"
      }
      env {
        name  = "ENABLE_NETWORK"
        value = "true"
      }
      env {
        name  = "HTTP_PROXY"
        value = "http://ssrfproxy:3128"
      }
      env {
        name  = "HTTPS_PROXY"
        value = "http://ssrfproxy:3128"
      }
      env {
        name  = "SANDBOX_PORT"
        value = "8194"
      }


      volume_mounts { 
        name = "sandbox"
        path = "/dependencies"
        }
    }
    volume {
      name = "sandbox"
      storage_type = "AzureFile"
      storage_name = azurerm_container_app_environment_storage.sandboxfileshare.name
    }
  }
  ingress {
    target_port = 8194
    # exposed_port = 3128
    external_enabled = false
    traffic_weight {
      # weight = 100
      percentage = 100
      latest_revision = true
    }
    transport = "tcp"
  }
}

resource "azurerm_container_app" "worker" {
  name                         = "worker"
  container_app_environment_id = azurerm_container_app_environment.dify-aca-env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  template {

    tcp_scale_rule {
      name = "worker"
      concurrent_requests = "10"
    }
    max_replicas = 10
    min_replicas = 1
    container {
      name   = "langgenius"
      image  = var.dify-api-image
      cpu    = 2
      memory = "4Gi"
      env {
        name  = "MODE"
        value = "worker"
      }
      env {
        name  = "LOG_LEVEL"
        value = "INFO"
      }
      env {
        name  = "SECRET_KEY"
        value = "sk-9f73s3ljTXVcMT3Blb3ljTqtsKiGHXVcMT3BlbkFJLK7U"
      }
      env {
        name  = "DB_USERNAME"
        value = azurerm_postgresql_flexible_server.postgres.administrator_login
      }
      env {
        name  = "DB_PASSWORD"
        value = azurerm_postgresql_flexible_server.postgres.administrator_password
      }
      env {
        name  = "DB_HOST"
        value = azurerm_postgresql_flexible_server.postgres.fqdn
      }
      env {
        name  = "DB_PORT"
        value = "5432"
      }

      env {
        name  = "DB_DATABASE"
        value = azurerm_postgresql_flexible_server_database.difypgsqldb.name
      }
      env {
        name  = "REDIS_HOST"
        value = azurerm_redis_cache.redis.hostname
      }
      env {
        name  = "REDIS_PORT"
        value = "6379"
      }
      env {
        name  = "REDIS_PASSWORD"
        value = azurerm_redis_cache.redis.primary_access_key
      }

      env {
        name  = "REDIS_USE_SSL"
        value = "false"
      }

      env {
        name  = "REDIS_DB"
        value = "0"
      }

      env {
        name  = "CELERY_BROKER_URL"
        value = "redis://:${azurerm_redis_cache.redis.primary_access_key}@${azurerm_redis_cache.redis.hostname}:6379/1"
      }

      env {
        name  = "STORAGE_TYPE"
        value = "azure-blob"
      }
      env {
        name  = "AZURE_BLOB_ACCOUNT_NAME"
        value = azurerm_storage_account.acafileshare.name
      }
      env {
        name  = "AZURE_BLOB_ACCOUNT_KEY"
        value = azurerm_storage_account.acafileshare.primary_access_key
      }
      env {
        name  = "AZURE_BLOB_ACCOUNT_URL"
        value = azurerm_storage_account.acafileshare.primary_blob_endpoint
      }
      env {
        name  = "AZURE_BLOB_CONTAINER_NAME"
        value = azurerm_storage_container.dfy.name
      }

      env {
        name  = "VECTOR_STORE"
        value = "pgvector"
      }

      env {
        name  = "PGVECTOR_HOST"
        value = azurerm_postgresql_flexible_server.postgres.fqdn
      }
      env {
        name  = "PGVECTOR_PORT"
        value = "5432"
      }
      env {
        name  = "PGVECTOR_USER"
        value = azurerm_postgresql_flexible_server.postgres.administrator_login
      }

      env {
        name  = "PGVECTOR_PASSWORD"
        value = azurerm_postgresql_flexible_server.postgres.administrator_password 
      }

      env {
        name  = "PGVECTOR_DATABASE"
        value = azurerm_postgresql_flexible_server_database.pgvector.name
      }

      env {
        name  = "INDEXING_MAX_SEGMENTATION_TOKENS_LENGTH"
        value = "1000"
      }
    }
  }
}

resource "azurerm_container_app" "api" {
  name                         = "api"
  container_app_environment_id = azurerm_container_app_environment.dify-aca-env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  template {
    tcp_scale_rule {
      name = "api"
      concurrent_requests = "10"
    }
    max_replicas = 10
    min_replicas = 0
    container {
      name   = "langgenius"
      image  = var.dify-api-image
      cpu    = 2
      memory = "4Gi"
      env {
        name  = "MODE"
        value = "api"
      }
      env {
        name  = "LOG_LEVEL"
        value = "INFO"
      }
      env {
        name  = "SECRET_KEY"
        value = "sk-9f73s3ljTXVcMT3Blb3ljTqtsKiGHXVcMT3BlbkFJLK7U"
      }

      env {
        name  = "CONSOLE_WEB_URL"
        value = ""
      }
      env {
        name  = "INIT_PASSWORD"
        value = ""
      }
      env {
        name  = "CONSOLE_API_URL"
        value = ""
      }
      env {
        name  = "SERVICE_API_URL"
        value = ""
      }

      env {
        name  = "APP_WEB_URL"
        value = ""
      }

      env {
        name  = "FILES_URL"
        value = ""
      }

      env {
        name  = "FILES_ACCESS_TIMEOUT"
        value = "300"
      }

      env {
        name  = "MIGRATION_ENABLED"
        value = "true"
      }

      env {
        name  = "SENTRY_DSN"
        value = ""
      }

      env {
        name  = "SENTRY_TRACES_SAMPLE_RATE"
        value = "1.0"
      }

      env {
        name  = "SENTRY_PROFILES_SAMPLE_RATE"
        value = "1.0"
      }


      env {
        name  = "DB_USERNAME"
        value = azurerm_postgresql_flexible_server.postgres.administrator_login
      }
      env {
        name  = "DB_PASSWORD"
        value = azurerm_postgresql_flexible_server.postgres.administrator_password
      }
      env {
        name  = "DB_HOST"
        value = azurerm_postgresql_flexible_server.postgres.fqdn
      }
      env {
        name  = "DB_PORT"
        value = "5432"
      }

      env {
        name  = "DB_DATABASE"
        value = azurerm_postgresql_flexible_server_database.difypgsqldb.name
      }

      env {
        name  = "WEB_API_CORS_ALLOW_ORIGINS"
        value = "*"
      }
      env {
        name  = "CONSOLE_CORS_ALLOW_ORIGINS"
        value = "*"
      }

      env {
        name  = "REDIS_HOST"
        value = azurerm_redis_cache.redis.hostname
      }
      env {
        name  = "REDIS_PORT"
        value = "6379"
      }
      env {
        name  = "REDIS_PASSWORD"
        value = azurerm_redis_cache.redis.primary_access_key
      }

      env {
        name  = "REDIS_USE_SSL"
        value = "false"
      }

      env {
        name  = "REDIS_DB"
        value = "0"
      }

      env {
        name  = "CELERY_BROKER_URL"
        value = "redis://:${azurerm_redis_cache.redis.primary_access_key}@${azurerm_redis_cache.redis.hostname}:6379/1"
      }

      env {
        name  = "STORAGE_TYPE"
        value = "azure-blob"
      }
      env {
        name  = "AZURE_BLOB_ACCOUNT_NAME"
        value = azurerm_storage_account.acafileshare.name
      }
      env {
        name  = "AZURE_BLOB_ACCOUNT_KEY"
        value = azurerm_storage_account.acafileshare.primary_access_key
      }
      env {
        name  = "AZURE_BLOB_ACCOUNT_URL"
        value = azurerm_storage_account.acafileshare.primary_blob_endpoint
      }
      env {
        name  = "AZURE_BLOB_CONTAINER_NAME"
        value = azurerm_storage_container.dfy.name
      }
      env {
        name  = "VECTOR_STORE"
        value = "pgvector"
      }

      env {
        name  = "PGVECTOR_HOST"
        value = azurerm_postgresql_flexible_server.postgres.fqdn
      }
      env {
        name  = "PGVECTOR_PORT"
        value = "5432"
      }
      env {
        name  = "PGVECTOR_USER"
        value = azurerm_postgresql_flexible_server.postgres.administrator_login
      }

      env {
        name  = "PGVECTOR_PASSWORD"
        value = azurerm_postgresql_flexible_server.postgres.administrator_password 
      }

      env {
        name  = "PGVECTOR_DATABASE"
        value = azurerm_postgresql_flexible_server_database.pgvector.name
      }

      env {
        name  = "CODE_EXECUTION_API_KEY"
        value = "dify-sandbox"
      }

      env {
        name  = "CODE_EXECUTION_ENDPOINT"
        value = "http://sandbox:8194" 
      }

      env {
        name  = "CODE_MAX_NUMBER"
        value = "9223372036854775807"
      }

      env {
        name  = "CODE_MIN_NUMBER"
        value = "-9223372036854775808"
      }

      env {
        name  = "CODE_MAX_STRING_LENGTH"
        value = "80000"
      }

      env {
        name  = "TEMPLATE_TRANSFORM_MAX_LENGTH"
        value = "80000"
      }

      env {
        name  = "CODE_MAX_OBJECT_ARRAY_LENGTH"
        value = "30"
      }

      env {
        name  = "CODE_MAX_STRING_ARRAY_LENGTH"
        value = "30"
      }

      env {
        name  = "CODE_MAX_NUMBER_ARRAY_LENGTH"
        value = "1000"
      }

      env {
        name  = "SSRF_PROXY_HTTP_URL"
        value = "http://ssrfproxy:3128"
      }

      env {
        name  = "SSRF_PROXY_HTTPS_URL"
        value = "http://ssrfproxy:3128"
      }

      env {
        name  = "INDEXING_MAX_SEGMENTATION_TOKENS_LENGTH"
        value = "1000"
      }

    }
  }

  ingress {
      target_port = 5001
      exposed_port = 5001
      external_enabled = false
      traffic_weight {
        # weight = 100
        percentage = 100
        latest_revision = true
      }
      transport = "tcp"
    }
}

resource "azurerm_container_app" "web" {
  name                         = "web"
  container_app_environment_id = azurerm_container_app_environment.dify-aca-env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  template {
    tcp_scale_rule {
      name = "web"
      concurrent_requests = "10"
    }
    max_replicas = 10
    min_replicas = 0
    container {
      name   = "langgenius"
      image  = "langgenius/dify-web:0.6.11"
      cpu    = 1
      memory = "2Gi"
       env {
        name  = "CONSOLE_API_URL"
        value = ""
      }

      env {
        name  = "APP_API_URL"
        value = ""
      }

      env {
        name  = "SENTRY_DSN"
        value = ""
      }
    }
  }

  ingress {
      target_port = 3000
      exposed_port = 3000
      external_enabled = false
      traffic_weight {
        # weight = 100
        percentage = 100
        latest_revision = true
      }
      transport = "tcp"
    }
}
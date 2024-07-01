## dify-azure-terraform
Deploy [langgenius/dify](https://github.com/langgenius/dify), an LLM based chat bot app on Azure with terraform.

### Topology
Front-end access:
- nginx -> Azure Container Apps (Serverless)

Back-end components:
- web -> Azure Container Apps (Serverless)
- api -> Azure Container Apps (Serverless)
- worker -> Azure Container Apps (minimum of 1 instance)
- sandbox -> Azure Container Apps (Serverless)
- ssrf_proxy -> Azure Container Apps (Serverless)
- db -> Azure Database for PostgreSQL
- vectordb -> Azure Database for PostgreSQL
- redis -> Azure Cache for Redis

Before you provision Dify, please check and set the variables in var.tf file.

### Terraform Variables Documentation

This document provides detailed descriptions of the variables used in the Terraform configuration for setting up the Dify environment.

#### Subscription ID

- **Variable Name**: `subscription-id`
- **Type**: `string`
- **Default Value**: `0000000000000`

#### Virtual Network Variables

##### Region

- **Variable Name**: `region`
- **Type**: `string`
- **Default Value**: `japaneast`

##### VNET Address IP Prefix

- **Variable Name**: `ip-prefix`
- **Type**: `string`
- **Default Value**: `10.99`

#### Storage Account

- **Variable Name**: `storage-account`
- **Type**: `string`
- **Default Value**: `acadifytest`

##### Storage Account Container

- **Variable Name**: `storage-account-container`
- **Type**: `string`
- **Default Value**: `dfy`

#### Redis

- **Variable Name**: `redis`
- **Type**: `string`
- **Default Value**: `acadifyredis`

#### PostgreSQL Flexible Server

- **Variable Name**: `psql-flexible`
- **Type**: `string`
- **Default Value**: `acadifypsql`

##### PostgreSQL User

- **Variable Name**: `pgsql-user`
- **Type**: `string`
- **Default Value**: `user`

##### PostgreSQL Password

- **Variable Name**: `pgsql-password`
- **Type**: `string`
- **Default Value**: `#QWEASDasdqwe`

#### ACA Environment Variables

##### ACA Environment

- **Variable Name**: `aca-env`
- **Type**: `string`
- **Default Value**: `dify-aca-env`

##### ACA Log Analytics Workspace

- **Variable Name**: `aca-loga`
- **Type**: `string`
- **Default Value**: `dify-loga`

##### ACA Certificate Path

- **Variable Name**: `aca-cert-path`
- **Type**: `string`
- **Default Value**: `./certs/difycert.pfx`

##### ACA Certificate Password

- **Variable Name**: `aca-cert-password`
- **Type**: `string`
- **Default Value**: `password`

##### ACA Dify Customer Domain

- **Variable Name**: `aca-dify-customer-domain`
- **Type**: `string`
- **Default Value**: `dify.nikadwang.com`

#### Container Images

##### Dify API Image

- **Variable Name**: `dify-api-image`
- **Type**: `string`
- **Default Value**: `langgenius/dify-api:0.6.11`

##### Dify Sandbox Image

- **Variable Name**: `dify-sandbox-image`
- **Type**: `string`
- **Default Value**: `langgenius/dify-sandbox:0.2.1`

##### Dify Web Image

- **Variable Name**: `dify-web-image`
- **Type**: `string`
- **Default Value**: `langgenius/dify-web:0.6.11`
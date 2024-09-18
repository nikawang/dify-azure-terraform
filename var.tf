variable "subscription-id" {
  type = string
  default = "25cc9009-2580-4987-936c-95aaab093023"
}

#virtual network variables
variable "region" {
  type = string
  default = "japaneast"
}

variable "ip-prefix" {
  type = string
  default = "10.99"
}
#end virtual network variables

variable "storage-account" {
  type = string
  default = "acadifytest"
}

variable "storage-account-container" {
  type = string
  default = "dfy" 
}

variable "redis" {
  type = string
  default = "acadifyredis"
}

variable "psql-flexible" {
  type = string
  default = "acadifypsql"
}

variable "pgsql-user" {
  type = string
  default = "user"
}

variable "pgsql-password" {
  type = string
  default = "#QWEASDasdqwe"
}

variable "aca-env" {
  type = string
  default = "dify-aca-env"
}

variable "aca-loga" {
  type = string
  default = "dify-loga"
}

variable "isProvidedCert" {
  type = bool
  default = true
}

variable "aca-cert-path" {
  type = string
  default = "./certs/difycert.pfx"
}

variable "aca-cert-password" {
  type = string
  default = "password"
}

variable "aca-dify-customer-domain" {
  type = string
  default = "dify.nikadwang.com"
}

variable "aca-app-min-count" {
  type = number
  default = 0
}

variable "is_aca_enabled" {
  type = bool
  default = false
}

variable "dify-api-image" {
  type = string
  # default = "langgenius/dify-api:0.6.11"
  default = "langgenius/dify-api:0.7.1"
}

variable "dify-sandbox-image" {
  type = string
  # default = "langgenius/dify-sandbox:0.2.1"
  default = "langgenius/dify-sandbox:0.2.6"
}

variable "dify-web-image" {
  type = string
  # default = "langgenius/dify-web:0.6.11"
  default = "langgenius/dify-web:0.7.1"
}
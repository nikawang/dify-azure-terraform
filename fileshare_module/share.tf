resource "azurerm_storage_share" "fileshare" {
  name                 = var.share_name
  storage_account_name = var.storage_account_name
  quota                = var.quota
}

data "local_file" "files" {
  for_each = fileset(var.local_mount_dir, "**/*")
  filename = "${var.local_mount_dir}/${each.value}"
}

locals {
  directories = compact(distinct(sort([
    for f in data.local_file.files : 
    replace(dirname(f.filename), var.local_mount_dir, ".") 
    if dirname(f.filename) != var.local_mount_dir && dirname(f.filename) != "."
  ])))
}

locals {
  root_files = { for f in data.local_file.files : f.filename => f if dirname(f.filename) == var.local_mount_dir }
  subdir_files = { for f in data.local_file.files : f.filename => f if dirname(f.filename) != var.local_mount_dir }
}

resource "azurerm_storage_share_directory" "directories" {
  for_each              = toset(local.directories)
  name                  = each.value
  storage_account_name  = var.storage_account_name
  share_name            = azurerm_storage_share.fileshare.name
}

resource "azurerm_storage_share_file" "root_files" {
  for_each = local.root_files

  name             = basename(each.value.filename)
  storage_share_id = azurerm_storage_share.fileshare.id
  source           = each.value.filename
  depends_on       = [azurerm_storage_share_directory.directories]
}

resource "azurerm_storage_share_file" "subdir_files" {
  for_each = local.subdir_files

  name             = basename(each.value.filename)
  storage_share_id = azurerm_storage_share.fileshare.id
  source           = each.value.filename
  path             = trimprefix(dirname(each.value.filename), "${var.local_mount_dir}/")
  depends_on       = [azurerm_storage_share_directory.directories]
}


output "share_name" {
  value       = azurerm_storage_share.fileshare.name
  description = "The name of the file share"
}

output "share_id" {
  value       = azurerm_storage_share.fileshare.id
  description = "The ID of the file share"
}
resource "azurerm_storage_share" "fileshare" {
  name                 = var.share_name
  storage_account_name = var.storage_account_name
  quota                = var.quota
}

locals {
  # Normalize the local mount directory path to use forward slashes
  local_mount_dir_normalized = replace(var.local_mount_dir, "\\", "/")
}

data "local_file" "files" {
  for_each = fileset(local.local_mount_dir_normalized, "**/*")
  # Normalize the filename to use forward slashes
  filename = replace("${local.local_mount_dir_normalized}/${each.value}", "\\", "/")
}

locals {
  files = [
    for f in data.local_file.files : {
      filename           = f.filename
      dirname_normalized = replace(dirname(f.filename), "\\", "/")
    }
  ]
}

locals {
  directories = compact(distinct(sort([
    for f in local.files :
    replace(
      f.dirname_normalized,
      local.local_mount_dir_normalized,
      "."
    )
    if f.dirname_normalized != local.local_mount_dir_normalized && f.dirname_normalized != "."
  ])))
}

locals {
  root_files = {
    for f in local.files : f.filename => f
    if f.dirname_normalized == local.local_mount_dir_normalized
  }
  subdir_files = {
    for f in local.files : f.filename => f
    if f.dirname_normalized != local.local_mount_dir_normalized
  }
}

resource "azurerm_storage_share_directory" "directories" {
  for_each          = toset(local.directories)
  name              = each.value
  storage_share_id  = azurerm_storage_share.fileshare.id
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
  path             = trimprefix(each.value.dirname_normalized, "${local.local_mount_dir_normalized}/")
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

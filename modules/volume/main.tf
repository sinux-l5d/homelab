locals {
  uid     = var.create_dirs.uid != "-1" ? "--uid ${var.create_dirs.uid}" : ""
  gid     = var.create_dirs.gid != "-1" ? "--gid ${var.create_dirs.gid}" : ""
  mode    = var.create_dirs.mode != "-1" ? "--mode ${var.create_dirs.mode}" : ""
  options = "${local.uid} ${local.gid} ${local.mode}"
}

resource "incus_storage_volume" "this" {
  name    = var.name
  project = var.project
  pool    = "local"
  config = {
    "security.shifted" = true
  }
  provisioner "local-exec" {
    command = coalesce(join("\n",
      [for dir in var.create_dirs.paths : "incus storage volume file create -p --type directory ${local.options} local ${self.name}${dir}"]
    ), "true")
  }

  dynamic "file" {
    for_each = var.files
    content {
      content            = file.value.content
      target_path        = file.value.target_path
      uid                = file.value.uid
      gid                = file.value.gid
      mode               = file.value.mode
      create_directories = true
    }
  }
}

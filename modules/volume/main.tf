locals {
  uid     = var.create_dirs.uid != "-1" ? "--uid ${var.create_dirs.uid}" : ""
  gid     = var.create_dirs.gid != "-1" ? "--gid ${var.create_dirs.gid}" : ""
  mode    = var.create_dirs.mode != "-1" ? "--mode ${var.create_dirs.mode}" : ""
  options = "${local.uid} ${local.gid} ${local.mode}"
}

resource "incus_storage_volume" "this" {
  name = var.name
  pool = "local"
  config = {
    "security.shifted" = true
  }
  provisioner "local-exec" {
    command = coalesce(join("\n",
      [for dir in var.create_dirs.paths : "incus storage volume file create -p --type directory ${local.options} local ${self.name}${dir}"]
    ), "true")
  }
}

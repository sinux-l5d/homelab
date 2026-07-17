resource "incus_instance" "this" {
  name  = var.name
  image = var.image
  config = merge(
    { for k, v in var.env : "environment.${k}" => v },
    var.config,
  )
  project = var.project

  dynamic "device" {
    for_each = { for i in var.volumes : i.volume_name => i.path }
    content {
      name = split("/", device.key)[0]
      type = "disk"
      properties = {
        "pool"   = "local"
        "source" = device.key
        "path"   = "${device.value}"
      }
    }
  }

  dynamic "device" {
    for_each = var.gpu_enabled == true ? ["0000:00:02.0"] : []
    content {
      name = "gpu"
      type = "gpu"
      properties = {
        "gputype" = "physical"
        "pci"     = device.value
      }
    }
  }

  wait_for {
    type = "ipv4"
  }
}

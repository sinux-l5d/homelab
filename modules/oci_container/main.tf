locals {
  provider = split(":", var.image)[0]
}

resource "incus_instance" "this" {
  name     = var.name
  image    = var.image
  running  = var.started
  profiles = var.profiles
  project  = var.project

  config = merge(
    {
      "oci.uid" = var.uid,
      "oci.gid" = var.gid,
    },
    local.provider == "linuxserver" ? {
      "environment.PUID" = "1000",
      "environment.PGID" = "1000",
    } : {},
    { for k, v in var.env : "environment.${k}" => v },
    var.config,
  )

  # Mount volumes
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

  # Connect GPU
  dynamic "device" {
    # TODO: change value to a configurable one
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

  # override network config
  dynamic "device" {
    for_each = var.ipv4 != null ? [var.ipv4] : []
    content {
      name = "eth0"
      type = "nic"
      properties = {
        "parent"       = "dmz",
        "nictype"      = "bridged"
        "ipv4.address" = device.value.address,
        # "ipv4.gateway" = device.value.gateway,
      }
    }
  }

  wait_for {
    type = "ipv4"
  }
}

locals {
  modules_path = "../../modules"
}

resource "incus_network" "phys" {
  name = "00e04c680216"
  type = "physical"
  config = {
    "parent" = "00e04c680216"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "incus_network" "external" {
  name = "external"
  type = "macvlan"
  config = {
    "parent" = incus_network.phys.name
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "incus_profile" "default" {
  name = "default"
  device {
    name = "eth0"
    type = "nic"
    properties = {
      "network" = incus_network.external.name
    }
  }

  device {
    name = "root"
    type = "disk"
    properties = {
      "path" = "/"
      "pool" = "local"
    }
  }
}

resource "incus_network" "phys" {
  name = "00e04c680216"
  type = "physical"
  config = {
    "parent" = "00e04c680216"
  }
}

resource "incus_network" "external" {
  name = "external"
  type = "macvlan"
  config = {
    "parent" = incus_network.phys.name
  }
}

resource "incus_network" "shared" {
  name = "shared"
  type = "bridge"
  config = {
    "ipv4.address" = "10.0.0.1/24"
    "ipv4.nat"     = "true"
  }
}

resource "incus_profile" "default" {
  name = "default"
  device {
    name = "eth0"
    type = "nic"
    properties = {
      "network" = incus_network.shared.name
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
resource "incus_profile" "lan" {
  name = "lan"
  config = {
    "cloud-init.network-config" = <<-EOF
    network:
      version: 2
      ethernets:
        eth0:
          dhcp4: true
          dhcp6: true
        eth1:
          dhcp4: true
          dhcp6: true
    EOF
    "cloud-init.user-data"      = <<-EOF
    #cloud-config
    package_update: true
    package_upgrade: true
    packages:
      - curl
    EOF
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      "network" = incus_network.shared.name
    }
  }

  device {
    name = "eth1"
    type = "nic"
    properties = {
      "network" = incus_network.external.name
    }
  }
}

resource "incus_instance" "multihomed" {
  name     = "multihomed"
  image    = "images:debian/trixie/cloud"
  profiles = ["default", incus_profile.lan.name]
}

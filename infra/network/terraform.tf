terraform {
  required_providers {
    incus = {
      source  = "lxc/incus"
      version = "~>1.0.0"
    }
  }
}

provider "incus" {
  generate_client_certificates = false
  accept_remote_certificate    = true

  default_remote = "lab1"

  remote {
    name    = "lab1"
    address = "https://192.168.1.200:8443"
  }
}

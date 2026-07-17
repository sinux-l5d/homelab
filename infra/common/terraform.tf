terraform {
  required_providers {
    incus = {
      source  = "lxc/incus"
      version = ">=1.1.0"
    }
  }
}

provider "incus" {
  generate_client_certificates = false
  accept_remote_certificate    = true

  default_remote = "lab1"

  remote {
    name    = "lab1"
    address = "https://192.168.1.199:8443"
  }

  remote {
    name     = "docker"
    address  = "https://docker.io"
    protocol = "oci"
  }

  remote {
    name     = "ghcr"
    address  = "https://ghcr.io"
    protocol = "oci"
  }
}

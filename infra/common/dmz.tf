locals {
  modules_path = "../../modules"
  zonefiles    = fileset("${path.module}/zones", "*.zone")
  secrets      = sensitive(yamldecode(file("${path.module}/ovh.secret.yaml")))
}

resource "incus_project" "dmz" {
  name        = "dmz"
  description = "Various DMZs to access apps"

  config = {
    "features.storage.volumes" = "true"
    "restricted"               = "false" # TODO: enable when following points are answered
    "restricted.backups"       = "allow"
    # "restricted.containers.interception" = "allow" # TODO: test if needed
    "restricted.devices.disk" = "block"
    # "restricted.devices.unix-char" = "block"
    "restricted.devices.nic"     = "block" # or managed ? or allow ? Unclear which one allows the next field to work
    "restricted.networks.access" = "dmz"
    # "restricted.networks.subnets" = "10.1.0.0/24" # maybe ?
  }
}

resource "incus_network" "dmz" {
  name    = "dmz"
  type    = "bridge"
  project = incus_project.dmz.name
  config = {
    "ipv4.address" = "10.1.0.1/24"
    "ipv4.dhcp"    = "true"
    # TODO: understand why all fail when turned off
    # if routing is enabled, why doesn't it work without NAT ?
    # apprently can't reach tls://9.9.9.9 when off, for example
    "ipv4.nat"     = "true"
    "ipv4.routing" = "true"
    "ipv6.address" = "none"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "incus_profile" "dmz" {
  name    = "default"
  project = incus_project.dmz.name
  device {
    name = "eth0"
    type = "nic"
    properties = {
      "network" = incus_network.dmz.name
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

module "volume_dns" {
  source = "${local.modules_path}/volume"

  name    = "dns"
  project = incus_project.dmz.name
  files = concat([
    {
      target_path = "/Corefile"
      mode        = "0440"
      uid         = 65532 # nonroot user in coredns image
      gid         = 65532
      content = templatestring(<<-EOF
      .:53 {
        forward . tls://dns.quad9.net {
          tls_servername dns.quad9.net
          health_check 5s
        }
        log
        errors
        loop
        reload
        cache 30
      }

      %%{ for zone in zones ~}
      $${zone}:53 {
        file zones/$${zone}.zone {
          reload 30s
        }
        log
        errors
      }
      %%{ endfor ~}
      EOF
      , { zones = [for file in local.zonefiles : trimsuffix(file, ".zone")] })
    }
    ], [for file in local.zonefiles : {
      target_path = "/zones/${file}"
      mode        = "0440"
      uid         = 65532
      gid         = 65532
      content     = templatefile("${path.module}/zones/${file}", { date = formatdate("YYYYMMDD", plantimestamp()) })
  }])
}

module "oci_dns" {
  source = "${local.modules_path}/oci_container"

  name    = "dns"
  project = incus_project.dmz.name
  image   = "docker:coredns/coredns:1.14.6"
  ipv4 = {
    address = "10.1.0.10"
    # gateway = "10.1.0.1"
  }
  config = {
    "oci.cwd" = "/etc/coredns"
  }
  volumes = [
    {
      volume_name = module.volume_dns.name
      path        = "/etc/coredns"
    }
  ]
}

module "volume_proxy" {
  source = "${local.modules_path}/volume"

  name    = "proxy"
  project = incus_project.dmz.name
  files = [
    {
      target_path = "/Caddyfile"
      mode        = "0440"
      # TODO: uncomment and make it work
      # uid         = 1000
      # gid         = 1000
      content = <<-EOF
      {
        acme_dns ovh {
          endpoint {$OVH_ENDPOINT}
          application_key {$OVH_APPLICATION_KEY}
          application_secret {$OVH_APPLICATION_SECRET}
          consumer_key {$OVH_CONSUMER_KEY}
        }
      }
      home.sinux.dev {
        respond "hello, home!"
      }
      EOF
    }
  ]
}

module "volume_proxy_data" {
  source = "${local.modules_path}/volume"

  name    = "proxy-data"
  project = incus_project.dmz.name
}

module "volume_proxy_config" {
  source = "${local.modules_path}/volume"

  name    = "proxy-config"
  project = incus_project.dmz.name
}

module "oci_proxy" {
  source = "${local.modules_path}/oci_container"

  name    = "proxy"
  project = incus_project.dmz.name
  image   = "ghcr:sinux-l5d/caddy-homelab:2.11.4"
  # TODO: uncomment and make it work
  # upstream container is root
  # should I maintain my own images ?
  # uid = 1000
  # gid = 1000
  ipv4 = {
    address = "10.1.0.11"
    # gateway = "10.1.0.1"
  }
  volumes = [
    {
      volume_name = module.volume_proxy.name
      path        = "/etc/caddy"
    },
    {
      volume_name = module.volume_proxy_data.name
      path        = "/data"
    },
    {
      volume_name = module.volume_proxy_config.name
      path        = "/config"
    },
  ]
  config = {
    "oci.cwd" = "/etc/caddy"
  }
  env = {
    "OVH_ENDPOINT"           = local.secrets.OVH_ENDPOINT
    "OVH_APPLICATION_KEY"    = local.secrets.OVH_APPLICATION_KEY
    "OVH_APPLICATION_SECRET" = local.secrets.OVH_APPLICATION_SECRET
    "OVH_CONSUMER_KEY"       = local.secrets.OVH_CONSUMER_KEY
  }
}

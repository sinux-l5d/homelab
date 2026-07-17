locals {
  backup_volumes = [
    # "backups",
    # "jellyfin-config",
    # "prowlarr-config",
    # "radarr-config",
    # "transmission-config",
  ]
}

# module "borg-data" {
#   source = "${local.modules_path}/volume"
#   name   = "borg-data"
#   create_dirs = {
#     paths = [
#       "/data",
#     ]
#   }
# }

# module "borg" {
#   source = "${local.modules_path}/oci_container"
#   name   = "borg"
#   image  = "docker:ainullcode/borg-ui:1.41.4"
#   volumes = concat([
#     {
#       volume_name = "${module.borg-data.name}/data"
#       path        = "/data"
#     },
#     ], [for v in local.backup_volumes : {
#       volume_name = v
#       path        = "/local/${v}"
#   }])
#   env = {
#     TZ   = "Europe/Paris"
#     PUID = "1000"
#     PGID = "1000"
#   }
#   profiles = [incus_profile.default.name]
# }

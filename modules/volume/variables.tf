variable "name" {
  description = "Name of the volume. It can include a subpath by adding a path, e.g. media-data/torrents."
  type        = string
}

variable "create_dirs" {
  description = "List of directories to create. Format as /foo/bar, /baz"
  type = object({
    paths = list(string)
    uid   = optional(string, "-1")
    gid   = optional(string, "-1")
    mode  = optional(string, "0755")
    }
  )
  default = {
    paths = []
    uid   = "1000"
    gid   = "1000"
    mode  = "0755"
  }
}

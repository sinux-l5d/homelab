variable "name" {
  description = "Name of the container"
  type        = string
}

variable "image" {
  description = "image name in <remote>:<repo>/<image>[:tag] format"
  type        = string
}

variable "started" {
  description = "Whether the container should be running"
  type        = bool
  default     = true
}

variable "profiles" {
  description = "Profiles to apply to the container"
  type        = list(string)
  default     = ["default"]
}

variable "env" {
  description = "Environment variables to pass to the app"
  type        = map(string)
  default     = {}
}

variable "volumes" {
  description = "Path to keep in a separate volume. key = volume name, value = path"
  type = list(object({
    volume_name = string
    path        = string
  }))
  default = []
}

variable "gpu_enabled" {
  description = "Whether to enable GPU acceleration"
  type        = bool
  default     = false
}

variable "config" {
  description = "Additionnal raw config to pass to instance"
  type        = map(string)
  default     = {}
}

variable "project" {
  description = "Project to create the container in"
  type        = string
  default     = "default"
}

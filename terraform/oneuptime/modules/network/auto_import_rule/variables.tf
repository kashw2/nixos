variable "name" {
  type = string
}

variable "description" {
  type = string
}

variable "ip_match_target" {
  type = string
}

variable "include_ping_only_hosts" {
  type    = bool
  default = true
}

variable "is_exclusion" {
  type    = bool
  default = false
}

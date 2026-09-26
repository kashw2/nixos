variable "hosts" {
  type = set(string)
  default = [
    "home",
    "homelab",
    "laptop",
    "media",
    "thinkpad",
  ]
}

variable "ONEUPTIME_RUNNER_KEY" {
  type      = string
  sensitive = true
}

variable "NIXOS_STATE_PASSPHRASE" {
  type      = string
  sensitive = true
}

variable "ONEUPTIME_PROBE_KEY" {
  type      = string
  sensitive = true
}

variable "vhosts" {
  type = set(string)
  default = [
    "alloy.media.local",
    "bazarr.media.local",
    "flaresolverr.media.local",
    "flood.media.local",
    "jellyfin.media.local",
    "oneuptime.media.local",
    "prowlarr.media.local",
    "radarr.media.local",
    "sonarr.media.local",
  ]
}

variable "SNMP_V3_USERNAME" {
  type    = string
  default = "oneuptime"
}

variable "SNMP_V3_AUTH_KEY" {
  type      = string
  sensitive = true
}

variable "SNMP_V3_PRIV_KEY" {
  type      = string
  sensitive = true
}

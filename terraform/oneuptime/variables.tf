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

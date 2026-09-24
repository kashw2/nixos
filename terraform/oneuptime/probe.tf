resource "oneuptime_probe" "media" {
  key           = var.ONEUPTIME_PROBE_KEY
  name          = "Probe-1"
  description   = "Private probe on media"
  probe_version = "13.0.0"

  should_auto_enable_probe_on_new_monitors = true
}

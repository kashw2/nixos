module "monitors" {
  source = "./modules/monitors"

  hosts  = var.hosts
  vhosts = var.vhosts
}

module "probe" {
  source = "./modules/probe"

  key           = var.ONEUPTIME_PROBE_KEY
  name          = "Probe-1"
  description   = "Private probe on media"
  probe_version = "13.0.0"
}

module "runner" {
  source = "./modules/runner"

  key  = var.ONEUPTIME_RUNNER_KEY
  name = "Runner"
}

module "telemetry" {
  source = "./modules/telemetry"

  name        = "OneUptime"
  description = "Ingestion Key for OneUptime"
}

module "status_page" {
  source = "./modules/status_page"

  vhost_monitors = module.monitors.vhost_ids
}

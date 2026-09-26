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
  host_monitors  = module.monitors.agent_ids
}

module "network" {
  source = "./modules/network"

  probe_id         = module.probe.id
  gateway          = "192.168.1.1"
  scan_cidr        = "192.168.1.0/24"
  import_cidr      = "192.168.1.0/27"
  snmp_v3_username = var.SNMP_V3_USERNAME
  snmp_v3_auth_key = var.SNMP_V3_AUTH_KEY
  snmp_v3_priv_key = var.SNMP_V3_PRIV_KEY
}

module "project" {
  source = "./modules/project"

  name                         = "Homelab"
  telemetry_retention_in_days  = 30
  metrics_retention_in_days    = 7
  audit_logs_retention_in_days = 7
}

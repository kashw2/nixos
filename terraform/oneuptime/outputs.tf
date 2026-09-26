output "agent_keys" {
  value     = module.monitors.agent_keys
  sensitive = true
}

output "ingestion_token" {
  value     = module.telemetry.secret_key
  sensitive = true
}

output "runner_id" {
  value = module.runner.id
}

output "probe_id" {
  value = module.probe.id
}

output "vhost_status_page_id" {
  value = module.status_page.vhosts_id
}

output "host_status_page_id" {
  value = module.status_page.hosts_id
}

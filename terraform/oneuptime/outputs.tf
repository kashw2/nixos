output "agent_keys" {
  value     = { for host, monitor in oneuptime_monitor.agent : host => monitor.server_monitor_secret_key }
  sensitive = true
}

output "runner_id" {
  value = oneuptime_runner.media.id
}

output "ingestion_token" {
  value     = oneuptime_telemetry_ingestion_key.alloy.secret_key
  sensitive = true
}

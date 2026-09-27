output "agent_keys" {
  value     = { for host, monitor in oneuptime_monitor.agent : host => monitor.server_monitor_secret_key }
  sensitive = true
}

output "agent_ids" {
  value = { for host, monitor in oneuptime_monitor.agent : host => monitor.id }
}

output "vhost_ids" {
  value = { for vhost, monitor in oneuptime_monitor.vhost : vhost => monitor.id }
}

resource "oneuptime_project" "this" {
  name = var.name

  default_telemetry_retention_in_days = var.telemetry_retention_in_days
  audit_logs_retention_in_days        = var.audit_logs_retention_in_days

  telemetry_retention_config = jsonencode({
    metrics = { default = var.metrics_retention_in_days }
  })
}

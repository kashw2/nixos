output "secret_key" {
  value     = oneuptime_telemetry_ingestion_key.this.secret_key
  sensitive = true
}

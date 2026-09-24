resource "oneuptime_telemetry_ingestion_key" "alloy" {
  name        = "OneUptime"
  description = "Ingestion Key for OneUptime"
  key_type    = "Server"
  is_enabled  = true
}

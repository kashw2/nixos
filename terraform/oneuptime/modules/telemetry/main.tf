resource "oneuptime_telemetry_ingestion_key" "this" {
  name        = var.name
  description = var.description
  key_type    = "Server"
  is_enabled  = true
}

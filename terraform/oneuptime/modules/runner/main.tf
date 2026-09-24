resource "oneuptime_runner" "this" {
  key         = var.key
  name        = var.name
  description = var.description

  can_run_runbooks       = true
  can_run_code_fix_tasks = false
  can_run_ai_commands    = false
}

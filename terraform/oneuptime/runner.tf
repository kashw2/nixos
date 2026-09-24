resource "oneuptime_runner" "media" {
  name = "Runner"
  key  = var.ONEUPTIME_RUNNER_KEY

  can_run_runbooks       = true
  can_run_code_fix_tasks = false
  can_run_ai_commands    = false
}

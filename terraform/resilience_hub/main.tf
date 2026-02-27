# Resilience Hub Module (Bonus)

variable "project_name" { type = string }

resource "aws_resiliencehub_resiliency_policy" "dr_policy" {
  name = "${var.project_name}-policy"
  policy = {
    software = {
      rto_in_secs = 300
      rpo_in_secs = 60
    }
    hardware = {
      rto_in_secs = 300
      rpo_in_secs = 60
    }
    az = {
      rto_in_secs = 300
      rpo_in_secs = 60
    }
    region = {
      rto_in_secs = 3600
      rpo_in_secs = 300
    }
  }
  tier = "MissionCritical"
}

# Simplified app resource - App creation is complex so we'll keep it minimal
resource "aws_resiliencehub_app" "dr_app" {
  name = "${var.project_name}-app"
  resiliency_policy_arn = aws_resiliencehub_resiliency_policy.dr_policy.arn
  # In a real scenario, you'd provide an app_template_body or use resource_mappings
}

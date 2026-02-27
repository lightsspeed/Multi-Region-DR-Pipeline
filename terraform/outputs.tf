output "primary_alb_dns" {
  value = module.compute_primary.alb_dns_name
}

output "secondary_alb_dns" {
  value = module.compute_secondary.alb_dns_name
}

output "primary_db_endpoint" {
  value = module.database.primary_endpoint
}

output "secondary_db_endpoint" {
  value = module.database.secondary_endpoint
}

output "dns_failover_name" {
  value = var.dns_domain
}

output "primary_asg_name" {
  value = module.compute_primary.asg_name
}

output "secondary_asg_name" {
  value = module.compute_secondary.asg_name
}

output "primary_health_check_id" {
  value = module.dns.primary_health_check_id
}

output "secondary_health_check_id" {
  value = module.dns.secondary_health_check_id
}

output "alb_this_lb_dns_name" {
  description = "The ALB DNS name"
  value       = module.alb.this_lb_dns_name
}

output "alb_target_group_arns" {
  description = "The ALB Traget Group ARN"
  value       = module.alb.target_group_arns[0]
}

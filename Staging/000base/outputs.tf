output "base_network_vpc_id" {
  description = "The VPC Id of the base network"
  value       = module.vpc.vpc_id
}

output "base_network_public_subnets" {
  description = "The VPC Id of the base network"
  value       = module.vpc.public_subnets
}

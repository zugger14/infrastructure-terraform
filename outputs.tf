output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

# output "ec2_public_ip" {
#   description = "Public IP address of the deployed EC2 instance"
#   value       = var.enable_ec2_deployment ? module.ec2[0].public_ip : null
# }

output "alb_dns_name" {
  description = "DNS name of the ECS Application Load Balancer"
  value       = var.enable_ecs_deployment ? module.alb[0].alb_dns_name : null
}

output "ecs_cluster_name" {
  description = "Name of the ECS Cluster"
  value       = var.enable_ecs_deployment ? module.ecs[0].cluster_name : null
}

output "ecs_services" {
  description = "List of active ECS Services deployed"
  value       = var.enable_ecs_deployment ? module.ecs[0].service_names : null
}

output "ecr_repositories" {
  description = "Map of ECR repository URLs for pushing container images"
  value       = module.ecr.repository_urls
}

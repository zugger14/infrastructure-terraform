output "cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "cluster_arn" {
  value = aws_ecs_cluster.main.arn
}

output "service_names" {
  value = [for s in aws_ecs_service.app_service : s.name]
}

output "target_group_arns" {
  value = { for k, v in aws_lb_target_group.app_tg : k => v.arn }
}

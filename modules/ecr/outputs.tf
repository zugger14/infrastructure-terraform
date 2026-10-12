output "repository_urls" {
  description = "Map of repository names to their full clone/push URLs"
  value       = { for k, v in aws_ecr_repository.app_repo : k => v.repository_url }
}

output "repository_arns" {
  description = "Map of repository names to ARNs"
  value       = { for k, v in aws_ecr_repository.app_repo : k => v.arn }
}

variable "repositories" {
  description = "List or map of ECR repository names to create"
  type        = list(string)
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

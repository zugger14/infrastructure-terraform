variable "vpc_id" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable "alb_listener_arn" {
  type = string
}

variable "alb_security_group" {
  type = string
}

variable "environment" {
  type = string
}

variable "apps" {
  type = map(object({
    cpu                 = number
    memory              = number
    container_port      = number
    container_image     = optional(string)
    desired_count       = number
    priority            = number
    path_pattern        = optional(string)
    host_header_pattern = optional(list(string))
    health_check_path   = optional(string)
  }))
}

variable "ecr_repository_urls" {
  description = "Map of application names to ECR repository URLs"
  type        = map(string)
  default     = {}
}

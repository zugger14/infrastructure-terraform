variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "deployment_target" {
  description = "Target infrastructure to deploy: 'ec2' (single EC2 host with Ansible), 'ecs' (Fargate containers + ALB), 'both', or 'none'"
  type        = string
  # No default so Terraform will interactively prompt: "var.deployment_target: Enter a value:"
  # If a default is needed in non-interactive CI/CD, pass -var="deployment_target=ecs" or define in terraform.tfvars
  validation {
    condition     = contains(["ec2", "ecs", "both", "none"], lower(var.deployment_target))
    error_message = "deployment_target must be one of: 'ec2', 'ecs', 'both', or 'none'."
  }
}

variable "enable_ec2_deployment" {
  description = "Flag to enable existing EC2 multi-app single-instance deployment"
  type        = bool
  default     = false
}

variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Key pair name for EC2 SSH access"
  type        = string
  default     = "shirish-webserver"
}

variable "enable_ecs_deployment" {
  description = "Flag to enable modern multi-service ECS Fargate deployment"
  type        = bool
  default     = false
}

variable "ecs_apps" {
  description = "Map of microservices/apps to deploy on ECS Fargate with lowest compute options"
  type = map(object({
    cpu                 = number # Lowest: 256 (.25 vCPU)
    memory              = number # Lowest: 512 (.5 GB RAM)
    container_port      = number
    container_image     = string
    desired_count       = number
    priority            = number
    path_pattern        = optional(string)
    host_header_pattern = optional(list(string))
    health_check_path   = optional(string)
  }))
  default = {
    portfolio = {
      cpu               = 256
      memory            = 512
      container_port    = 3000
      container_image   = "public.ecr.aws/docker/library/node:22-alpine" # Replace with custom ECR image
      desired_count     = 1
      priority          = 500
      path_pattern      = "/*" # Root catch-all for portfolio
      health_check_path = "/"
    }
    ams = {
      cpu                 = 256
      memory              = 512
      container_port      = 80
      container_image     = "public.ecr.aws/docker/library/php:7.4-apache" # Replace with custom ECR image
      desired_count       = 1
      priority            = 200
      host_header_pattern = ["ams.*"]
      path_pattern        = "/ams*"
      health_check_path   = "/"
    }
    musicbook = {
      cpu                 = 256
      memory              = 512
      container_port      = 8000
      container_image     = "public.ecr.aws/docker/library/php:7.4-fpm-alpine" # Replace with custom ECR image
      desired_count       = 1
      priority            = 300
      host_header_pattern = ["musicbook.*"]
      path_pattern        = "/musicbook*"
      health_check_path   = "/"
    }
  }
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones to spread subnets across"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "vpc_id" {
  type = string
}

variable "public_subnet" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "key_name" {
  type = string
}

variable "environment" {
  type = string
}

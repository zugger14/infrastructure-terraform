data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source = "./modules/vpc"

  vpc_cidr           = var.vpc_cidr
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)
  environment        = var.environment
}

# ==============================================================================
# 1. EC2 Deployment (Controlled via variable deployment_target or enable_ec2_deployment)
# ==============================================================================
module "ec2" {
  count  = (var.deployment_target == "ec2" || var.deployment_target == "both" || var.enable_ec2_deployment) ? 1 : 0
  source = "./modules/ec2"

  vpc_id        = module.vpc.vpc_id
  public_subnet = module.vpc.public_subnets[0]
  instance_type = var.ec2_instance_type
  key_name      = var.key_name
  environment   = var.environment
}

# ==============================================================================
# 2. Elastic Container Registry (ECR) - DRY per application
# ==============================================================================
module "ecr" {
  source = "./modules/ecr"

  repositories = keys(var.ecs_apps)
  environment  = var.environment
}

# ==============================================================================
# 3. ECS Fargate Serverless Containers with Application Load Balancer
# ==============================================================================
module "alb" {
  count  = (var.deployment_target == "ecs" || var.deployment_target == "both" || var.enable_ecs_deployment) ? 1 : 0
  source = "./modules/alb"

  vpc_id         = module.vpc.vpc_id
  public_subnets = module.vpc.public_subnets
  environment    = var.environment
}

module "ecs" {
  count  = (var.deployment_target == "ecs" || var.deployment_target == "both" || var.enable_ecs_deployment) ? 1 : 0
  source = "./modules/ecs"

  vpc_id              = module.vpc.vpc_id
  subnets             = module.vpc.public_subnets
  alb_listener_arn    = module.alb[0].http_listener_arn
  alb_security_group  = module.alb[0].alb_security_group_id
  environment         = var.environment
  ecr_repository_urls = module.ecr.repository_urls

  apps = var.ecs_apps
}

# ==============================================================================
# Elastic Container Registry (ECR) - DRY loop per application
# ==============================================================================
resource "aws_ecr_repository" "app_repo" {
  for_each = toset(var.repositories)

  name                 = each.key
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "ecr-${each.key}-${var.environment}"
  }
}

# Lifecycle policy: retain the latest 5 images to keep AWS storage costs minimal
resource "aws_ecr_lifecycle_policy" "cleanup_policy" {
  for_each = aws_ecr_repository.app_repo

  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only last 5 untagged or tagged images"
        selection = {
          tagStatus   = "any"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 14
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

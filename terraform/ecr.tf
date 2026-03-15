# ECR Repository
resource "aws_ecr_repository" "creorez_ecr" {
  name                 = "cloud/creorez-latex"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.project_name}-ecr"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ECR Lifecycle Policy — keep only last 5 images
resource "aws_ecr_lifecycle_policy" "creorez_ecr_policy" {
  repository = aws_ecr_repository.creorez_ecr.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
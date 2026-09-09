resource "aws_ecr_repository" "this" {
  for_each = toset(var.service_names)

  name = "${var.name_prefix}/${each.value}"

  # Required by the GitOps flow. See environments.md in docket-architecture.
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  tags = { Name = "${var.name_prefix}-${each.value}" }
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each = aws_ecr_repository.this

  repository = each.value.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep only the last ${var.max_image_count} images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = var.max_image_count
      }
      action = { type = "expire" }
    }]
  })
}

resource "aws_ecr_repository" "this" {
  for_each = toset(var.service_names)

  name = "docket/${each.value}"

  # Requisito del flujo GitOps. Ver ambientes.md en docket-architecture.
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  tags = { Name = "docket-${each.value}" }
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each = aws_ecr_repository.this

  repository = each.value.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Conservar solo las ultimas ${var.max_image_count} imagenes"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = var.max_image_count
      }
      action = { type = "expire" }
    }]
  })
}

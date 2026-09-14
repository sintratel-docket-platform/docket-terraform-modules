resource "aws_ecr_repository" "this" {
  for_each = toset(var.service_names)

  name = "${var.name_prefix}/${each.value}"

  # A GitOps flow needs immutable tags: with a tag that gets rewritten the
  # manifest does not change, so nothing detects the new image and promotion
  # between environments stops working. Configurable because a consumer outside
  # that flow may legitimately want otherwise; the default keeps it safe.
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  tags = { Name = "${var.name_prefix}-${each.value}" }
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each = aws_ecr_repository.this

  repository = each.value.name

  # ECR lets the first rule that selects an image decide its fate, and requires
  # the `any` rule to come last. Promoted images are therefore selected first,
  # by the tag a promotion adds, and counted apart: publishing to development
  # never pushes out an image staging or production still declares.
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep the last ${var.max_promoted_image_count} promoted images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = [var.promoted_tag_prefix]
          countType     = "imageCountMoreThan"
          countNumber   = var.max_promoted_image_count
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep only the last ${var.max_image_count} other images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.max_image_count
        }
        action = { type = "expire" }
      },
    ]
  })
}

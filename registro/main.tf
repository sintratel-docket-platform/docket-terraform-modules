# Un repositorio de ECR por microservicio.
#
# La capa gratuita de ECR cubre 500 MB al mes, asi que la politica de ciclo de
# vida no es opcional: sin ella el historial de tags crece hasta desbordarla.

resource "aws_ecr_repository" "this" {
  for_each = toset(var.service_names)

  name = "docket/${each.value}"

  # Las etiquetas de imagen no se pueden sobrescribir. Es lo que hace posible la
  # promocion declarativa entre ambientes: si una etiqueta pudiera reescribirse,
  # el manifiesto no cambiaria y Argo CD no detectaria nada.
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

output "role_arn" {
  description = "ARN del rol. Lo consume la anotacion del ServiceAccount en el stack plataforma."
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Nombre del rol."
  value       = aws_iam_role.this.name
}
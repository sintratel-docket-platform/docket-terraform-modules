output "repository_urls" {
  description = "URL de cada repositorio, indexada por nombre de servicio. La consumen los manifiestos y la pipeline."
  value       = { for k, v in aws_ecr_repository.this : k => v.repository_url }
}

output "repository_arns" {
  description = "ARN de los repositorios. Los consume el modulo identidad-ci para acotar el rol de build."
  value       = [for r in aws_ecr_repository.this : r.arn]
}

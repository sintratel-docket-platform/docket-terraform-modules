output "build_role_arn" {
  description = "Rol que asume el job de construccion de imagenes."
  value       = aws_iam_role.build.arn
}

output "deploy_role_arn" {
  description = "Rol que asume el job que ejecuta Terraform."
  value       = aws_iam_role.deploy.arn
}

output "oidc_provider_arn" {
  description = "Proveedor OIDC de GitHub, unico por cuenta."
  value       = aws_iam_openid_connect_provider.github.arn
}

output "parameter_prefix" {
  description = "Prefijo del arbol de parametros del ambiente."
  value       = "/docket/${var.environment}/"
}

output "parameter_arns" {
  description = "ARN de los parametros creados. Los consume la politica del rol de IRSA del ambiente."
  value       = [for p in aws_ssm_parameter.this : p.arn]
}

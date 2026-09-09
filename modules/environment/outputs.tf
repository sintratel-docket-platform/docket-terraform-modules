output "parameter_prefix" {
  description = "Prefix of the environment parameter tree."
  value       = "/docket/${var.environment}/"
}

output "parameter_arns" {
  description = "ARNs of the created parameters. Consumed by the environment IRSA role policy."
  value       = [for p in aws_ssm_parameter.this : p.arn]
}

resource "aws_ssm_parameter" "this" {
  for_each = toset(var.parameter_names)

  name   = "/docket/${var.environment}/${each.value}"
  type   = "SecureString"
  value  = "PENDIENTE"
  key_id = var.kms_key_id != "" ? var.kms_key_id : null

  # El valor real se carga fuera de Terraform y no debe pisarse en el siguiente apply.
  lifecycle {
    ignore_changes = [value]
  }

  tags = { Name = "docket-${var.environment}-${each.value}" }
}

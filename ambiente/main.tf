resource "aws_ssm_parameter" "this" {
  for_each = toset(var.parameter_names)

  name             = "/docket/${var.environment}/${each.value}"
  type             = "SecureString"
  value_wo         = var.parameter_values[each.value]
  value_wo_version = var.parameter_value_versions[each.value]
  key_id           = var.kms_key_id != "" ? var.kms_key_id : null

  tags = { Name = "docket-${var.environment}-${each.value}" }
}

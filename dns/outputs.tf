output "zone_id" {
  description = "Identificador de la zona alojada."
  value       = aws_route53_zone.this.zone_id
}

output "name_servers" {
  description = "Nameservers que hay que delegar en el registrador."
  value       = aws_route53_zone.this.name_servers
}

output "certificate_arn" {
  description = "ARN del certificado, para asociarlo al listener del balanceador."
  value       = aws_acm_certificate.this.arn
}

output "hosts" {
  description = "Host de cada ambiente."
  value = {
    prod    = local.host_prod
    staging = "staging.${local.host_prod}"
    dev     = "dev.${local.host_prod}"
  }
}

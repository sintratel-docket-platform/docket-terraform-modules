output "zone_id" {
  description = "Hosted zone identifier."
  value       = aws_route53_zone.this.zone_id
}

output "name_servers" {
  description = "Nameservers to delegate at the registrar."
  value       = aws_route53_zone.this.name_servers
}

output "certificate_arn" {
  description = "Certificate ARN, to attach to the load balancer listener."
  value       = aws_acm_certificate.this.arn
}

output "hosts" {
  description = "Host of each environment."
  value = {
    prod    = local.host_prod
    staging = "staging.${local.host_prod}"
    dev     = "dev.${local.host_prod}"
  }
}

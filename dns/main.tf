locals {
  host_prod = "${var.subdomain}.${var.domain_name}"
}

resource "aws_route53_zone" "this" {
  name = var.domain_name

  tags = { Name = "docket-${var.domain_name}" }
}

# One certificate for the production host and a wildcard covering the other environments.
resource "aws_acm_certificate" "this" {
  domain_name               = local.host_prod
  subject_alternative_names = ["*.${local.host_prod}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = { Name = "docket-${local.host_prod}" }
}

resource "aws_route53_record" "validation" {
  for_each = {
    for d in aws_acm_certificate.this.domain_validation_options : d.domain_name => d
    if d.domain_name == local.host_prod
  }

  zone_id         = aws_route53_zone.this.zone_id
  name            = each.value.resource_record_name
  type            = each.value.resource_record_type
  records         = [each.value.resource_record_value]
  ttl             = 60
  allow_overwrite = true
}

# Separate from the certificate: without delegated nameservers this wait times out.
resource "aws_acm_certificate_validation" "this" {
  count = var.validate_certificate ? 1 : 0

  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for r in aws_route53_record.validation : r.fqdn]

  timeouts {
    create = "10m"
  }
}

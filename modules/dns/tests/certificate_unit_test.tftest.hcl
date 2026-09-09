# Plan-mode tests for the dns module.
#
# The certificate has to cover both the host and everything under it, because
# the ingress serves each service on its own subdomain. A certificate covering
# only the apex fails at the first service hostname, and it fails in the
# browser rather than in the plan.

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock-access-key"
  secret_key                  = "mock-secret-key"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
}

variables {
  name_prefix = "example"
  domain_name = "example.com"
  subdomain   = "app"
}

run "certificate_covers_the_host_and_its_children" {
  command = plan

  assert {
    condition     = aws_acm_certificate.this.domain_name == "app.example.com"
    error_message = "The certificate must name the environment host."
  }

  assert {
    condition = contains(
      aws_acm_certificate.this.subject_alternative_names,
      "*.app.example.com"
    )
    error_message = "Each service gets its own subdomain, so the wildcard is required."
  }
}

run "zone_is_the_apex_not_the_subdomain" {
  command = plan

  # Delegation is set at the registrar for the apex. A zone created for the
  # subdomain would never be reached.
  assert {
    condition     = aws_route53_zone.this.name == "example.com"
    error_message = "The hosted zone must be the apex domain."
  }
}

run "validation_can_be_deferred" {
  command = plan

  # The first apply cannot validate: the registrar does not point at these name
  # servers yet, and waiting would block the whole stack.
  variables {
    validate_certificate = false
  }

  assert {
    condition     = length(aws_acm_certificate_validation.this) == 0
    error_message = "Validation must be skippable on the first apply."
  }
}

run "rejects_a_prefix_that_is_not_a_name" {
  command = plan

  variables {
    name_prefix = "Example.Com"
  }

  expect_failures = [var.name_prefix]
}

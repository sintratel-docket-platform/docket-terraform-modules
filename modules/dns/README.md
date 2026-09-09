# `dns` module

Route 53 hosted zone and ACM certificate for the three environments.

The certificate covers the production host plus a wildcard that spans `staging` and `dev`, and any environment added later.

## Two-step activation

Certificate validation requires the nameservers to be delegated at the registrar already, and that delegation is a manual step with propagation latency. That is why `validate_certificate` is separate:

1. `apply` with `validate_certificate = false`. Creates the zone and the certificate, which stays pending.
2. Delegate the nameservers from the `name_servers` output at the registrar.
3. `apply` with `validate_certificate = true`. Waits for ACM to complete validation.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.14 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 6.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_acm_certificate.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate_validation.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) | resource |
| [aws_route53_record.validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_zone.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain registered with the external registrar. | `string` | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for every resource name this module creates. Keeps the module reusable: it names nothing after a particular project. | `string` | n/a | yes |
| <a name="input_subdomain"></a> [subdomain](#input\_subdomain) | Subdomain the environments hang from. | `string` | n/a | yes |
| <a name="input_validate_certificate"></a> [validate\_certificate](#input\_validate\_certificate) | Wait for ACM to validate the certificate. Requires the nameservers to be delegated already. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_certificate_arn"></a> [certificate\_arn](#output\_certificate\_arn) | Certificate ARN, to attach to the load balancer listener. |
| <a name="output_hosts"></a> [hosts](#output\_hosts) | Host of each environment. |
| <a name="output_name_servers"></a> [name\_servers](#output\_name\_servers) | Nameservers to delegate at the registrar. |
| <a name="output_zone_id"></a> [zone\_id](#output\_zone\_id) | Hosted zone identifier. |
<!-- END_TF_DOCS -->

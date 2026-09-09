# `environment` module

SSM Parameter Store tree for one environment, under the `/docket/<environment>/` prefix.


## How values are handled

Parameters are written with the **write-only** argument `value_wo`, paired with `value_wo_version`. Terraform sends the value to the API and never persists it: not to state, not to the plan file.

Because Terraform cannot read a write-only value back, it cannot detect a change either. Rotating a secret means incrementing its entry in `parameter_value_versions`; without that, a new value in `parameter_values` is not written. That is the intended behaviour, not a defect.

`parameter_values` is declared `ephemeral`, so the value does not survive the run in any Terraform artifact.

This replaced an earlier pattern that wrote a placeholder and used `lifecycle { ignore_changes = [value] }`. The placeholder still reached state, and the real content lived entirely outside Terraform's model.

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
| [aws_ssm_parameter.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name. Determines the prefix of the parameter tree. | `string` | n/a | yes |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | KMS key used to encrypt the parameters. Left empty, SSM uses the AWS-managed key, which has no cost. | `string` | `""` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for every resource name this module creates. Keeps the module reusable: it names nothing after a particular project. | `string` | n/a | yes |
| <a name="input_parameter_names"></a> [parameter\_names](#input\_parameter\_names) | Parameter names created under the environment prefix. | `list(string)` | n/a | yes |
| <a name="input_parameter_value_versions"></a> [parameter\_value\_versions](#input\_parameter\_value\_versions) | Rotation version indexed by parameter name; increment a value to write that parameter again. | `map(number)` | n/a | yes |
| <a name="input_parameter_values"></a> [parameter\_values](#input\_parameter\_values) | Write-only values indexed by parameter name. | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_parameter_arns"></a> [parameter\_arns](#output\_parameter\_arns) | ARNs of the created parameters. Consumed by the environment IRSA role policy. |
| <a name="output_parameter_prefix"></a> [parameter\_prefix](#output\_parameter\_prefix) | Prefix of the environment parameter tree. |
<!-- END_TF_DOCS -->

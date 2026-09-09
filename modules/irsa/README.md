# `irsa` module

An IAM role assumable only by one specific `ServiceAccount` in one specific namespace, through the cluster OIDC provider.



## Why it lives in the ephemeral stack

The trust policy points at the cluster OIDC provider, whose URL contains an identifier that changes on every recreation. A persistent role would be left with broken trust after the first shutdown cycle. See `AGENTS.md`.

---

The condition on `sub` requires the exact value `system:serviceaccount:<namespace>:<service_account>`. Without it, any `ServiceAccount` in the cluster could assume the role, and the separation between environments would disappear with nothing to signal it.

## Inline policy and managed policy

A role may carry either, or both. The inline policy is written in `policy_json` and is created only when that arrives with content. Managed policies are passed by ARN in `managed_policy_arns`.

The EBS driver is the managed-policy case. It uses `AmazonEBSCSIDriverPolicy`, which AWS maintains, and copying its JSON into the repository would leave a copy that ages without warning.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.14 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.63.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.gestionadas](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_policy_document.trust](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_managed_policy_arns"></a> [managed\_policy\_arns](#input\_managed\_policy\_arns) | AWS managed policies attached to the role. | `list(string)` | `[]` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace of the authorised ServiceAccount. | `string` | n/a | yes |
| <a name="input_oidc_provider_arn"></a> [oidc\_provider\_arn](#input\_oidc\_provider\_arn) | Cluster OIDC provider. It changes on every recreation. | `string` | n/a | yes |
| <a name="input_oidc_provider_url"></a> [oidc\_provider\_url](#input\_oidc\_provider\_url) | OIDC provider URL without the scheme, which is the format the conditions are written in. | `string` | n/a | yes |
| <a name="input_policy_json"></a> [policy\_json](#input\_policy\_json) | Role permission policy, as JSON. Empty when the role only carries managed policies. | `string` | `""` | no |
| <a name="input_policy_name"></a> [policy\_name](#input\_policy\_name) | Name of the inline role policy. | `string` | `""` | no |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | IAM role name. | `string` | n/a | yes |
| <a name="input_service_account"></a> [service\_account](#input\_service\_account) | Name of the authorised ServiceAccount. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | Role ARN. Consumed by the ServiceAccount annotation in the platform stack. |
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | Role name. |
<!-- END_TF_DOCS -->

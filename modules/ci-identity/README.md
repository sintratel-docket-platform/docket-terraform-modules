# `ci-identity` module

GitHub OIDC provider and the two roles the pipeline assumes.

| Role | Assumed by | Scope |
|---|---|---|
| `GitHubActionsBuildRole` | The job that builds and publishes images | ECR only |
| `GitHubActionsDeployRole` | The job that runs Terraform | EC2, VPC, IAM, S3, EKS and Route 53 |

The separation answers the least-privilege criterion of card `18`. The build job has no business creating clusters.



## Scoped policy candidates

`GitHubActionsDeployRole` still carries the broad policy. A scoped candidate and a plan-only role exist alongside it, unattached, pending a full CloudTrail-backed apply and teardown cycle to confirm the action set. See `docs/IAM-POLICY-VALIDATION.md`.

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
| [aws_iam_openid_connect_provider.github](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_policy.deploy_scoped_candidate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.build](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.deploy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.plan_candidate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.build](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.deploy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.plan_candidate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_policy_document.build_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.build_trust](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.deploy_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.deploy_permissions_scoped_candidate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.deploy_trust](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.plan_permissions_candidate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | AWS account that contains the Docket resources. | `string` | n/a | yes |
| <a name="input_allowed_branches"></a> [allowed\_branches](#input\_allowed\_branches) | Branches allowed to assume the roles. A role assumable from any branch is equivalent to a shared credential. | `list(string)` | <pre>[<br/>  "main"<br/>]</pre> | no |
| <a name="input_build_repositories"></a> [build\_repositories](#input\_build\_repositories) | Repositories whose build job may assume the ECR-scoped role. | `list(string)` | n/a | yes |
| <a name="input_ecr_repository_arns"></a> [ecr\_repository\_arns](#input\_ecr\_repository\_arns) | ECR repositories the build role has permissions on. | `list(string)` | n/a | yes |
| <a name="input_github_org"></a> [github\_org](#input\_github\_org) | GitHub organisation that hosts the project repositories. | `string` | n/a | yes |
| <a name="input_github_org_id"></a> [github\_org\_id](#input\_github\_org\_id) | Numeric identifier of the organisation. | `string` | n/a | yes |
| <a name="input_infra_repository"></a> [infra\_repository](#input\_infra\_repository) | Infrastructure repository, the only one authorised to assume the role that runs Terraform. | `string` | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for every resource name this module creates. Keeps the module reusable: it names nothing after a particular project. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region that contains the regional Docket resources. | `string` | n/a | yes |
| <a name="input_repository_ids"></a> [repository\_ids](#input\_repository\_ids) | Numeric identifier of each repository, indexed by name. | `map(string)` | n/a | yes |
| <a name="input_state_bucket_arn"></a> [state\_bucket\_arn](#input\_state\_bucket\_arn) | Terraform state bucket, which the infrastructure role needs read and write access to. | `string` | n/a | yes |
| <a name="input_thumbprints"></a> [thumbprints](#input\_thumbprints) | GitHub certificate thumbprints. AWS has verified these on its own since 2023, and the field remains required by the API. | `list(string)` | <pre>[<br/>  "6938fd4d98bab03faadb97b34396831e3780aea1"<br/>]</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_build_role_arn"></a> [build\_role\_arn](#output\_build\_role\_arn) | Role assumed by the image build job. |
| <a name="output_deploy_role_arn"></a> [deploy\_role\_arn](#output\_deploy\_role\_arn) | Role assumed by the job that runs Terraform. |
| <a name="output_deploy_scoped_candidate_policy_arn"></a> [deploy\_scoped\_candidate\_policy\_arn](#output\_deploy\_scoped\_candidate\_policy\_arn) | Unattached scoped policy candidate that requires CloudTrail validation before use. |
| <a name="output_oidc_provider_arn"></a> [oidc\_provider\_arn](#output\_oidc\_provider\_arn) | GitHub OIDC provider, one per account. |
| <a name="output_plan_candidate_role_arn"></a> [plan\_candidate\_role\_arn](#output\_plan\_candidate\_role\_arn) | Plan-only role candidate that requires a complete plan validation before workflow use. |
| <a name="output_trusted_subjects"></a> [trusted\_subjects](#output\_trusted\_subjects) | Every OIDC subject the roles in this module trust, as build and deploy.<br/>Exposed because this is the whole authorisation boundary for CI: without<br/>it the only way to review what a workflow may assume is to read a rendered<br/>IAM policy after an apply. Contains no secret; the subjects are public<br/>facts about the repositories. |
<!-- END_TF_DOCS -->

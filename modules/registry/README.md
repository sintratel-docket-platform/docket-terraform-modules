# `registry` module

One ECR repository per microservice, with a lifecycle policy that prunes old images.

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
| [aws_ecr_lifecycle_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy) | resource |
| [aws_ecr_repository.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_image_tag_mutability"></a> [image\_tag\_mutability](#input\_image\_tag\_mutability) | Whether published tags can be overwritten. IMMUTABLE is what a GitOps promotion flow requires. | `string` | `"IMMUTABLE"` | no |
| <a name="input_max_image_count"></a> [max\_image\_count](#input\_max\_image\_count) | Number of images retained per repository. The ECR free tier covers 500 MB per month, so pruning is not optional. | `number` | `10` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for every resource name this module creates. Keeps the module reusable: it names nothing after a particular project. | `string` | n/a | yes |
| <a name="input_scan_on_push"></a> [scan\_on\_push](#input\_scan\_on\_push) | When true, ECR scans every published image for known vulnerabilities. | `bool` | `true` | no |
| <a name="input_service_names"></a> [service\_names](#input\_service\_names) | Microservice names. One ECR repository is created per name. | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_repository_arns"></a> [repository\_arns](#output\_repository\_arns) | Repository ARNs. Consumed by the ci-identity module to scope the build role. |
| <a name="output_repository_urls"></a> [repository\_urls](#output\_repository\_urls) | URL of each repository, indexed by service name. Consumed by the manifests and the pipeline. |
<!-- END_TF_DOCS -->

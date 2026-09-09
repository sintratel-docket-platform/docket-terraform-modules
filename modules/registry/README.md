# `registry` module

One ECR repository per microservice, with a lifecycle policy that prunes old images.

## Inputs

| Variable | Type | Required | Purpose |
|---|---|---|---|
| `service_names` | list(string) | Yes | One repository per name |
| `max_image_count` | number | No, `10` | Images retained per repository |
| `scan_on_push` | bool | No, `true` | Vulnerability scan on publish |

The ECR free tier covers 500 MB per month, so pruning is not optional. Scanning on push provides evidence for the security area and has no cost in its basic tier.

## Outputs

| Output | What it returns | Who consumes it |
|---|---|---|
| `repository_urls` | Map of service to repository URL | Deployment manifests and the pipeline |
| `repository_arns` | List of ARNs | The `ci-identity` module, to scope the build role |

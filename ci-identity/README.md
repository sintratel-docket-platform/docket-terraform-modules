# `ci-identity` module

GitHub OIDC provider and the two roles the pipeline assumes.

| Role | Assumed by | Scope |
|---|---|---|
| `GitHubActionsBuildRole` | The job that builds and publishes images | ECR only |
| `GitHubActionsDeployRole` | The job that runs Terraform | EC2, VPC, IAM, S3, EKS and Route 53 |

The separation answers the least-privilege criterion of card `18`. The build job has no business creating clusters.

## Inputs

| Variable | Type | Required | Purpose |
|---|---|---|---|
| `github_org` | string | Yes | Organisation owning the repositories |
| `build_repositories` | list(string) | Yes | Repositories allowed to assume the build role |
| `infra_repository` | string | Yes | The only repository allowed to assume the Terraform role |
| `allowed_branches` | list(string) | No, `["main"]` | Branches accepted by the trust policy |
| `ecr_repository_arns` | list(string) | Yes | Repositories the build role acts on |
| `state_bucket_arn` | string | Yes | Bucket the Terraform role needs to read and write |

The trust policy is built with a condition on `sub` of the form `repo:<org>@<org_id>/<repo>@<repo_id>:ref:refs/heads/<branch>`. GitHub issues the subject in this immutable form, with numeric identifiers. Without scoping repository and branch, the role would be assumable by any repository in the organisation.

## Outputs

| Output | What it returns | Who consumes it |
|---|---|---|
| `build_role_arn` | Build role ARN | The image build workflow |
| `deploy_role_arn` | Terraform role ARN | The infrastructure workflow |
| `oidc_provider_arn` | GitHub OIDC provider | Reference for additional policies |

## Scoped policy candidates

`GitHubActionsDeployRole` still carries the broad policy. A scoped candidate and a plan-only role exist alongside it, unattached, pending a full CloudTrail-backed apply and teardown cycle to confirm the action set. See `docs/IAM-POLICY-VALIDATION.md`.

output "build_role_arn" {
  description = "Role assumed by the image build job."
  value       = aws_iam_role.build.arn
}

output "deploy_role_arn" {
  description = "Role assumed by the job that runs Terraform."
  value       = aws_iam_role.deploy.arn
}

output "deploy_scoped_candidate_policy_arn" {
  description = "Unattached scoped policy candidate that requires CloudTrail validation before use."
  value       = aws_iam_policy.deploy_scoped_candidate.arn
}

output "gitops_pin_role_arn" {
  description = "Role the manifests repository assumes on an allowed branch to tag promoted images. Null without gitops_repository."
  value       = try(one(values(aws_iam_role.manifests_pin)).arn, null)
}

output "gitops_read_role_arn" {
  description = "Role the manifests repository assumes, from pull requests too, to check that an image exists. Null without gitops_repository."
  value       = try(one(values(aws_iam_role.manifests_read)).arn, null)
}

output "oidc_provider_arn" {
  description = "GitHub OIDC provider, one per account."
  value       = aws_iam_openid_connect_provider.github.arn
}

output "plan_candidate_role_arn" {
  description = "Plan-only role candidate that requires a complete plan validation before workflow use."
  value       = aws_iam_role.plan_candidate.arn
}

output "trusted_subjects" {
  description = <<-EOT
    Every OIDC subject the roles in this module trust, as build, deploy, manifests_read and manifests_pin.
    Exposed because this is the whole authorisation boundary for CI: without
    it the only way to review what a workflow may assume is to read a rendered
    IAM policy after an apply. Contains no secret; the subjects are public
    facts about the repositories.
  EOT
  value = {
    build          = local.build_subjects
    deploy         = local.infra_subjects
    manifests_read = local.manifests_read_subjects
    manifests_pin  = local.manifests_pin_subjects
  }
}

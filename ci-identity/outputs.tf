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

output "oidc_provider_arn" {
  description = "GitHub OIDC provider, one per account."
  value       = aws_iam_openid_connect_provider.github.arn
}

output "plan_candidate_role_arn" {
  description = "Plan-only role candidate that requires a complete plan validation before workflow use."
  value       = aws_iam_role.plan_candidate.arn
}

output "repository_urls" {
  description = "URL of each repository, indexed by service name. Consumed by the manifests and the pipeline."
  value       = { for k, v in aws_ecr_repository.this : k => v.repository_url }
}

output "repository_arns" {
  description = "Repository ARNs. Consumed by the ci-identity module to scope the build role."
  value       = [for r in aws_ecr_repository.this : r.arn]
}

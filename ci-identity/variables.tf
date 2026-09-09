variable "account_id" {
  description = "AWS account that contains the Docket resources."
  type        = string
}

variable "github_org" {
  description = "GitHub organisation that hosts the project repositories."
  type        = string
}

variable "github_org_id" {
  description = "Numeric identifier of the organisation."
  type        = string
}

variable "repository_ids" {
  description = "Numeric identifier of each repository, indexed by name."
  type        = map(string)
}

variable "region" {
  description = "AWS region that contains the regional Docket resources."
  type        = string
}

variable "build_repositories" {
  description = "Repositories whose build job may assume the ECR-scoped role."
  type        = list(string)
}

variable "infra_repository" {
  description = "Infrastructure repository, the only one authorised to assume the role that runs Terraform."
  type        = string
}

variable "allowed_branches" {
  description = "Branches allowed to assume the roles. A role assumable from any branch is equivalent to a shared credential."
  type        = list(string)
  default     = ["main"]
}

variable "ecr_repository_arns" {
  description = "ECR repositories the build role has permissions on."
  type        = list(string)
}

variable "state_bucket_arn" {
  description = "Terraform state bucket, which the infrastructure role needs read and write access to."
  type        = string
}

variable "thumbprints" {
  description = "GitHub certificate thumbprints. AWS has verified these on its own since 2023, and the field remains required by the API."
  type        = list(string)
  default     = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

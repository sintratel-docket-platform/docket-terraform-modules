# Plan-mode tests for the ci-identity module.
#
# This module is what lets GitHub Actions reach AWS with no stored key, so the
# trust conditions are the entire boundary. GitHub issues subjects in immutable
# form — the organisation and the repository as numeric identifiers — which is
# what stops a deleted-and-recreated repository of the same name inheriting the
# trust. A subject matched loosely, or with a wildcard, gives any workflow in
# any repository the deploy role.

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock-access-key"
  secret_key                  = "mock-secret-key"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
}

variables {
  name_prefix   = "example"
  account_id    = "000000000000"
  github_org    = "example-org"
  github_org_id = "12345"
  region        = "us-east-1"
  repository_ids = {
    "example-auth-api" = "111"
    "example-infra"    = "222"
  }
  build_repositories  = ["example-auth-api"]
  infra_repository    = "example-infra"
  allowed_branches    = ["main"]
  ecr_repository_arns = ["arn:aws:ecr:us-east-1:000000000000:repository/example/auth-api"]
  state_bucket_arn    = "arn:aws:s3:::example-state"
}

run "subjects_are_immutable" {
  command = plan

  # Both identifiers present: the organisation and the repository. Without them
  # a recreated repository with the same name inherits the trust.
  assert {
    condition = contains(
      output.trusted_subjects.build,
      "repo:example-org@12345/example-auth-api@111:ref:refs/heads/main"
    )
    error_message = "The build subject must carry the numeric org and repository identifiers."
  }

  assert {
    condition = contains(
      output.trusted_subjects.deploy,
      "repo:example-org@12345/example-infra@222:ref:refs/heads/main"
    )
    error_message = "The deploy subject must carry the numeric org and repository identifiers."
  }
}

run "no_subject_is_a_wildcard" {
  command = plan

  # StringLike with a wildcard is the usual shortcut and it hands the role to
  # every repository in the organisation.
  assert {
    condition = alltrue([
      for s in concat(output.trusted_subjects.build, output.trusted_subjects.deploy) :
      !strcontains(s, "*")
    ])
    error_message = "A wildcard subject trusts every repository in the organisation."
  }
}

run "build_cannot_assume_deploy" {
  command = plan

  # The build role publishes images; the deploy role changes infrastructure.
  # The infrastructure repository must not appear in the build trust.
  assert {
    condition = alltrue([
      for s in output.trusted_subjects.build : !strcontains(s, "example-infra@222")
    ])
    error_message = "The build role must not trust the infrastructure repository."
  }
}

run "the_provider_federates_only_github_actions" {
  command = plan

  assert {
    condition = contains(
      aws_iam_openid_connect_provider.github.client_id_list,
      "sts.amazonaws.com"
    )
    error_message = "Without the audience the provider accepts tokens minted elsewhere."
  }

  assert {
    condition     = aws_iam_openid_connect_provider.github.url == "https://token.actions.githubusercontent.com"
    error_message = "The provider must federate GitHub Actions and nothing else."
  }
}

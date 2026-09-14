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

# ---------- Manifests repository: read and pin roles ----------
#
# The manifests repository checks that a promoted image exists, and after a
# merge tags it so the registry keeps it. A pull request, including one nobody
# has reviewed yet, may read the registry but must never write to it; IAM can
# only tell the two apart in the trust policy, so they are two roles.

run "manifests_roles_are_opt_in" {
  command = plan

  assert {
    condition     = length(aws_iam_role.manifests_read) == 0 && length(aws_iam_role.manifests_pin) == 0
    error_message = "Without gitops_repository the module must create neither role."
  }
}

run "manifests_read_trusts_pull_requests_and_branches" {
  command = plan

  variables {
    gitops_repository = "example-gitops"
    repository_ids = {
      "example-auth-api" = "111"
      "example-infra"    = "222"
      "example-gitops"   = "333"
    }
  }

  assert {
    condition = toset(output.trusted_subjects.manifests_read) == toset([
      "repo:example-org@12345/example-gitops@333:pull_request",
      "repo:example-org@12345/example-gitops@333:ref:refs/heads/main",
    ])
    error_message = "The read role trusts exactly the manifests repository's pull requests and allowed branches, in immutable form."
  }
}

run "manifests_pin_never_trusts_pull_requests" {
  command = plan

  variables {
    gitops_repository = "example-gitops"
    repository_ids = {
      "example-auth-api" = "111"
      "example-infra"    = "222"
      "example-gitops"   = "333"
    }
  }

  assert {
    condition = output.trusted_subjects.manifests_pin == [
      "repo:example-org@12345/example-gitops@333:ref:refs/heads/main",
    ]
    error_message = "The pin role writes to the registry, so only an allowed branch may assume it, never a pull request."
  }
}

run "manifests_read_can_only_describe" {
  command = plan

  variables {
    gitops_repository = "example-gitops"
    repository_ids = {
      "example-auth-api" = "111"
      "example-infra"    = "222"
      "example-gitops"   = "333"
    }
  }

  assert {
    condition = alltrue([
      for s in jsondecode(aws_iam_role_policy.manifests_read["example-gitops"].policy).Statement :
      toset(flatten([s.Action])) == toset(["ecr:DescribeImages"]) &&
      toset(flatten([s.Resource])) == toset(["arn:aws:ecr:us-east-1:000000000000:repository/example/auth-api"])
    ])
    error_message = "The read role may only describe images, and only in the given repositories."
  }
}

run "manifests_pin_can_only_tag_existing_images" {
  command = plan

  variables {
    gitops_repository = "example-gitops"
    repository_ids = {
      "example-auth-api" = "111"
      "example-infra"    = "222"
      "example-gitops"   = "333"
    }
  }

  assert {
    condition = alltrue([
      for s in jsondecode(aws_iam_role_policy.manifests_pin["example-gitops"].policy).Statement :
      toset(flatten([s.Action])) == toset(["ecr:BatchGetImage", "ecr:DescribeImages", "ecr:PutImage"]) &&
      toset(flatten([s.Resource])) == toset(["arn:aws:ecr:us-east-1:000000000000:repository/example/auth-api"])
    ])
    error_message = "The pin role may read a manifest and put it back under a new tag, in the given repositories, and nothing else."
  }
}

run "manifests_repository_must_have_an_id" {
  command = plan

  variables {
    gitops_repository = "example-unknown"
  }

  expect_failures = [var.gitops_repository]
}

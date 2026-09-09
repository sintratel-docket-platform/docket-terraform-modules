# Plan-mode tests for the irsa module.
#
# The trust policy is the whole security boundary. A role that trusts the OIDC
# provider without binding the exact namespace and service account can be
# assumed by any pod in the cluster, which is the difference between IRSA and
# handing every workload the same credentials.

# A real provider, deliberately: aws_iam_policy_document is computed by the
# provider without any API call, and mocking it would mean asserting against
# our own fixture instead of against the policy the module actually renders.
# The fake credentials are never used because plan makes no call here.
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock-access-key"
  secret_key                  = "mock-secret-key"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
}

variables {
  role_name         = "example-external-dns"
  oidc_provider_arn = "arn:aws:iam::000000000000:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE"
  oidc_provider_url = "oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE"
  namespace         = "platform"
  service_account   = "external-dns"
  policy_name       = "example-external-dns"
  policy_json       = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
}

run "trust_binds_one_service_account" {
  command = plan

  # Not a wildcard, and not the namespace alone: the subject names both, so a
  # different service account in the same namespace cannot assume this role.
  assert {
    condition = strcontains(
      aws_iam_role.this.assume_role_policy,
      "system:serviceaccount:platform:external-dns"
    )
    error_message = "The trust policy must bind the exact namespace and service account."
  }
}

run "trust_carries_no_wildcard_subject" {
  command = plan

  assert {
    condition     = !strcontains(aws_iam_role.this.assume_role_policy, "system:serviceaccount:*")
    error_message = "A wildcard subject would let any pod in the cluster assume the role."
  }
}

run "trust_requires_the_sts_audience" {
  command = plan

  # Without the audience condition the role trusts tokens minted for another
  # audience entirely.
  assert {
    condition     = strcontains(aws_iam_role.this.assume_role_policy, "sts.amazonaws.com")
    error_message = "The trust policy must require the sts.amazonaws.com audience."
  }
}

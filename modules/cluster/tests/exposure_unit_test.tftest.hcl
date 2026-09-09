# Plan-mode tests for the cluster module.
#
# The API endpoint reachability is the invariant that matters here. A cluster
# reached this project's main branch with 0.0.0.0/0 on the endpoint, and the
# validation below is what stops that recurring; these tests are what stop the
# validation being quietly removed.

# A real provider, deliberately: the IAM policy documents are rendered by the
# provider with no API call, and a mock returns a placeholder that is not valid
# JSON. Plan makes no call here, so the credentials below are never used.
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock-access-key"
  secret_key                  = "mock-secret-key"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
}

variables {
  name_prefix              = "example"
  cluster_name             = "example-eks"
  kubernetes_version       = "1.31"
  private_subnet_ids       = ["subnet-00000000000000001", "subnet-00000000000000002"]
  public_subnet_ids        = ["subnet-00000000000000003", "subnet-00000000000000004"]
  node_security_group_id   = "sg-00000000000000001"
  public_access_cidrs      = ["203.0.113.0/24"]
  cluster_admin_principals = ["arn:aws:iam::000000000000:user/example"]
}

run "rejects_an_open_endpoint" {
  command = plan

  variables {
    public_access_cidrs = ["0.0.0.0/0"]
  }

  expect_failures = [var.public_access_cidrs]
}

run "rejects_an_open_endpoint_among_others" {
  command = plan

  # The check has to look at every entry, not just the first.
  variables {
    public_access_cidrs = ["203.0.113.0/24", "0.0.0.0/0"]
  }

  expect_failures = [var.public_access_cidrs]
}

run "rejects_an_empty_cidr_list" {
  command = plan

  # An empty list would leave the endpoint's exposure to the provider default
  # rather than to a decision recorded here.
  variables {
    public_access_cidrs = []
  }

  expect_failures = [var.public_access_cidrs]
}

run "audit_logging_is_on_by_default" {
  command = plan

  assert {
    condition = alltrue([
      for t in ["audit", "authenticator"] :
      contains(aws_eks_cluster.this.enabled_cluster_log_types, t)
    ])
    error_message = "The audit and authenticator logs are what makes access reviewable."
  }
}

run "rejects_a_prefix_that_is_not_a_name" {
  command = plan

  variables {
    name_prefix = "Example_Cluster"
  }

  expect_failures = [var.name_prefix]
}

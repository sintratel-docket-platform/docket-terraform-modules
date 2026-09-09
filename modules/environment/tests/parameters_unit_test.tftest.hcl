# Plan-mode tests for the environment module.
#
# Two invariants: a parameter holding a secret must be a SecureString, and its
# value must be write-only. A plain String is readable by anything with the
# path, and a value passed the ordinary way is written to state in clear.

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock-access-key"
  secret_key                  = "mock-secret-key"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
}

variables {
  name_prefix     = "example"
  environment     = "dev"
  parameter_names = ["jwt-secret", "redis-password"]
  parameter_values = {
    "jwt-secret"     = "not-a-real-secret"
    "redis-password" = "not-a-real-secret"
  }
  parameter_value_versions = {
    "jwt-secret"     = 1
    "redis-password" = 1
  }
}

run "every_parameter_is_encrypted" {
  command = plan

  assert {
    condition = alltrue([
      for p in aws_ssm_parameter.this : p.type == "SecureString"
    ])
    error_message = "A secret stored as a plain String is readable by anything that can read the path."
  }
}

run "values_are_write_only" {
  command = plan

  # value is computed and unknown at plan time, so the observable proof that
  # the write-only path is in use is that every parameter carries a version:
  # value_wo cannot be set without one. If someone switches to plain value, the
  # secret lands in state, and state lives in S3.
  assert {
    condition = alltrue([
      for p in aws_ssm_parameter.this : p.value_wo_version != null
    ])
    error_message = "The value must be supplied write-only, never through value."
  }
}

run "paths_are_namespaced_by_environment" {
  command = plan

  # Two environments sharing a path would have them overwrite each other.
  assert {
    condition = alltrue([
      for p in aws_ssm_parameter.this : strcontains(p.name, "/dev/")
    ])
    error_message = "Each environment needs its own parameter prefix."
  }
}

run "rejects_an_unknown_environment" {
  command = plan

  variables {
    environment = "qa"
  }

  expect_failures = [var.environment]
}

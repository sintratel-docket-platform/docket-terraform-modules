# Plan-mode tests for the registry module.
#
# The immutability default is the one that matters: a mutable tag silently
# breaks GitOps promotion, because the manifest never changes and nothing
# detects the new image.

mock_provider "aws" {}

variables {
  name_prefix   = "example"
  service_names = ["frontend", "auth-api", "users-api"]
}

run "one_repository_per_service" {
  command = plan

  assert {
    condition     = length(aws_ecr_repository.this) == 3
    error_message = "One repository is created per service name."
  }
}

run "tags_are_immutable_by_default" {
  command = plan

  assert {
    condition = alltrue([
      for r in aws_ecr_repository.this : r.image_tag_mutability == "IMMUTABLE"
    ])
    error_message = "A mutable tag breaks GitOps promotion; the default must be IMMUTABLE."
  }
}

run "mutability_can_be_opted_out_of" {
  command = plan

  variables {
    image_tag_mutability = "MUTABLE"
  }

  assert {
    condition = alltrue([
      for r in aws_ecr_repository.this : r.image_tag_mutability == "MUTABLE"
    ])
    error_message = "The variable must reach the resource."
  }
}

run "rejects_an_invalid_mutability" {
  command = plan

  variables {
    image_tag_mutability = "SOMETIMES"
  }

  expect_failures = [var.image_tag_mutability]
}

run "every_repository_is_pruned" {
  command = plan

  # The ECR free tier covers 500 MB a month; without a lifecycle policy five
  # services accumulating tags exhaust it.
  assert {
    condition     = length(aws_ecr_lifecycle_policy.this) == 3
    error_message = "Every repository needs a lifecycle policy."
  }
}

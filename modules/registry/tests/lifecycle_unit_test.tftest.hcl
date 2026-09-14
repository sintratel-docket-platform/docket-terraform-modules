# Plan-mode tests for the registry lifecycle policy.
#
# A promotion tags the image it moves with `promoted-<environment>-<version>`.
# The policy must keep those images however many newer ones are published,
# because an environment that declares a pruned image cannot start. ECR gives
# the first rule that selects an image the only say over it, so the promoted
# rule has to come first and the catch-all `any` rule last.

mock_provider "aws" {}

variables {
  name_prefix   = "example"
  service_names = ["frontend", "auth-api"]
}

run "promoted_images_are_selected_first" {
  command = plan

  assert {
    condition = alltrue([
      for p in aws_ecr_lifecycle_policy.this :
      jsondecode(p.policy).rules[0].rulePriority == 1 &&
      jsondecode(p.policy).rules[0].selection.tagStatus == "tagged" &&
      jsondecode(p.policy).rules[0].selection.tagPrefixList == ["promoted-"]
    ])
    error_message = "The first rule must select images tagged with the promoted prefix."
  }
}

run "promoted_images_have_their_own_count" {
  command = plan

  variables {
    max_image_count          = 10
    max_promoted_image_count = 20
  }

  assert {
    condition = alltrue([
      for p in aws_ecr_lifecycle_policy.this :
      jsondecode(p.policy).rules[0].selection.countNumber == 20 &&
      jsondecode(p.policy).rules[1].selection.countNumber == 10
    ])
    error_message = "Promoted images are kept by max_promoted_image_count, everything else by max_image_count."
  }
}

run "everything_else_is_selected_last" {
  command = plan

  assert {
    condition = alltrue([
      for p in aws_ecr_lifecycle_policy.this :
      length(jsondecode(p.policy).rules) == 2 &&
      jsondecode(p.policy).rules[1].selection.tagStatus == "any" &&
      jsondecode(p.policy).rules[1].rulePriority > jsondecode(p.policy).rules[0].rulePriority
    ])
    error_message = "ECR requires the any rule to have the highest priority number, after the promoted rule."
  }
}

run "the_prefix_is_configurable" {
  command = plan

  variables {
    promoted_tag_prefix = "released-"
  }

  assert {
    condition = alltrue([
      for p in aws_ecr_lifecycle_policy.this :
      jsondecode(p.policy).rules[0].selection.tagPrefixList == ["released-"]
    ])
    error_message = "The variable must reach the policy; the module names nothing after one project."
  }
}

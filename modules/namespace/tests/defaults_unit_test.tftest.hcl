# Plan-mode tests for the namespace module.
#
# Mock provider, so they need neither a cluster nor credentials. They assert the
# four isolation layers a namespace is useless without, and the two rules that
# exist because breaking them silently widens access: no secrets in the operator
# role, and no exec in production.

mock_provider "kubernetes" {}

variables {
  environment = "dev"
}

run "namespace_is_named_after_the_environment" {
  command = plan

  assert {
    condition     = kubernetes_namespace.this.metadata[0].name == "dev"
    error_message = "The namespace takes the environment name."
  }
}

run "all_four_isolation_layers_are_created" {
  command = plan

  # A namespace on its own isolates nothing. These are the layers that do.
  assert {
    condition     = kubernetes_resource_quota.this.metadata[0].name != ""
    error_message = "The resource quota is missing."
  }

  assert {
    condition     = kubernetes_limit_range.this.metadata[0].name != ""
    error_message = "The LimitRange is missing. Without it a pod with no resources is rejected by the quota."
  }

  assert {
    condition     = kubernetes_role.operator.metadata[0].name != ""
    error_message = "The operator Role is missing."
  }

  assert {
    condition     = kubernetes_network_policy.isolation.metadata[0].name != ""
    error_message = "The NetworkPolicy is missing. Without it any namespace reaches any other."
  }
}

run "pod_security_admission_labels_are_set" {
  command = plan

  assert {
    condition     = kubernetes_namespace.this.metadata[0].labels["pod-security.kubernetes.io/enforce"] == "baseline"
    error_message = "Pod Security Admission must enforce at least baseline."
  }

  assert {
    condition     = kubernetes_namespace.this.metadata[0].labels["pod-security.kubernetes.io/warn"] == "restricted"
    error_message = "The warn level reports what a pod would need to reach restricted."
  }
}

run "the_operator_role_never_grants_secrets" {
  command = plan

  # An operator who can read secrets holds the environment JWT_SECRET, and from
  # there the rest of the RBAC stops mattering.
  assert {
    condition = alltrue([
      for rule in kubernetes_role.operator.rule :
      !contains(rule.resources, "secrets")
    ])
    error_message = "The operator Role must never grant access to secrets."
  }
}

run "exec_is_closed_in_production" {
  command = plan

  variables {
    environment = "prod"
    allow_exec  = false
  }

  # Opening a shell in a pod exposes its mounted secrets, granting through the
  # back door what omitting `secrets` denies at the front.
  assert {
    condition = alltrue([
      for rule in kubernetes_role.operator.rule :
      !contains(rule.resources, "pods/exec")
    ])
    error_message = "With allow_exec = false the Role must not grant pods/exec."
  }
}

run "service_account_does_not_automount_its_token" {
  command = plan

  assert {
    condition     = kubernetes_service_account.application.automount_service_account_token == false
    error_message = "The application services do not call the cluster API; that token would only be useful to steal."
  }
}

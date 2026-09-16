# Plan-mode tests for addon_version_overrides.
#
# The invariant that matters here: an overridden addon must carry no
# dependency on aws_eks_cluster.this at all, not merely resolve to the same
# value it would have without the override. A fallback expression that still
# references the data source would inherit its "known after apply" deferral
# whenever the cluster resource has any unrelated pending change, which is
# exactly the incidental-upgrade problem this input exists to avoid.

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

run "rejects_an_override_key_that_is_not_a_managed_addon" {
  command = plan

  variables {
    addon_version_overrides = {
      "aws-ebs-csi-driver" = "v1.0.0-eksbuild.1"
    }
  }

  expect_failures = [var.addon_version_overrides]
}

run "no_overrides_leaves_every_addon_tracking_aws_default" {
  command = plan

  # The default ({}). Every managed addon still gets a data source instance,
  # exactly as before this input existed. The resolved version itself is not
  # asserted here: it is read live from AWS and is not known during `plan`.
  assert {
    condition = alltrue([
      for name in ["vpc-cni", "coredns", "kube-proxy", "eks-pod-identity-agent"] :
      contains(keys(data.aws_eks_addon_version.this), name)
    ])
    error_message = "Every managed addon must have a data source instance when no override is set."
  }
}

run "overridden_addon_has_no_data_source_instance" {
  command = plan

  variables {
    addon_version_overrides = {
      "kube-proxy" = "v1.99.0-eksbuild.1"
    }
  }

  # The structural proof: kube-proxy is absent from the data source's keys
  # entirely, not merely defaulted to it, so it carries no dependency on
  # aws_eks_cluster.this and is unaffected by an unrelated pending change
  # elsewhere on the cluster resource.
  assert {
    condition     = !contains(keys(data.aws_eks_addon_version.this), "kube-proxy")
    error_message = "An overridden addon must not have a data source instance."
  }

  assert {
    condition = alltrue([
      for name in ["vpc-cni", "coredns", "eks-pod-identity-agent"] :
      contains(keys(data.aws_eks_addon_version.this), name)
    ])
    error_message = "Every addon without an override must still have a data source instance."
  }

  assert {
    condition     = aws_eks_addon.others["kube-proxy"].addon_version == "v1.99.0-eksbuild.1"
    error_message = "An overridden addon must use the pinned version, not the data source."
  }
}

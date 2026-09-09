data "aws_default_tags" "current" {}

data "aws_iam_policy_document" "cluster_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster" {
  name               = "${var.name_prefix}-plano-control"
  assume_role_policy = data.aws_iam_policy_document.cluster_assume.json

  tags = { Name = "${var.name_prefix}-plano-control" }
}

resource "aws_iam_role_policy_attachment" "cluster" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = var.public_access_cidrs
  }

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = false
  }

  enabled_cluster_log_types = var.enabled_log_types

  # Without this the cluster can be created before the role has its policy.
  depends_on = [aws_iam_role_policy_attachment.cluster]
}

resource "aws_iam_openid_connect_provider" "cluster" {
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = var.oidc_thumbprints
}

data "aws_iam_policy_document" "nodes_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "nodes" {
  name               = "${var.name_prefix}-nodes"
  assume_role_policy = data.aws_iam_policy_document.nodes_assume.json

  tags = { Name = "${var.name_prefix}-nodes" }
}

resource "aws_iam_role_policy_attachment" "nodes" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  ])

  role       = aws_iam_role.nodes.name
  policy_arn = each.value
}

resource "aws_launch_template" "nodes" {
  name_prefix = "${var.name_prefix}-nodes-"

  # The network one carries the load balancer rule; the cluster one carries the
  # control plane route to the kubelet.
  vpc_security_group_ids = [
    var.node_security_group_id,
    aws_eks_cluster.this.vpc_config[0].cluster_security_group_id,
  ]

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.node_disk_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # Instances are created by the autoscaling group, not Terraform, so
  # default_tags does not reach them and they must be propagated by the launch template.
  tag_specifications {
    resource_type = "instance"
    tags          = merge(data.aws_default_tags.current.tags, { Name = "${var.name_prefix}-nodo" })
  }

  tag_specifications {
    resource_type = "volume"
    tags          = merge(data.aws_default_tags.current.tags, { Name = "${var.name_prefix}-nodo" })
  }
}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.name_prefix}-nodes"
  node_role_arn   = aws_iam_role.nodes.arn
  subnet_ids      = var.private_subnet_ids

  instance_types = [var.node_instance_type]
  capacity_type  = var.node_capacity_type
  ami_type       = "AL2023_x86_64_STANDARD"

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  launch_template {
    id      = aws_launch_template.nodes.id
    version = aws_launch_template.nodes.latest_version
  }

  depends_on = [aws_iam_role_policy_attachment.nodes]
}

data "aws_eks_addon_version" "this" {
  for_each = toset(["vpc-cni", "coredns", "kube-proxy", "eks-pod-identity-agent"])

  addon_name         = each.value
  kubernetes_version = aws_eks_cluster.this.version
  most_recent        = false
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name  = aws_eks_cluster.this.name
  addon_name    = "vpc-cni"
  addon_version = data.aws_eks_addon_version.this["vpc-cni"].version

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  # Without enableNetworkPolicy the CNI accepts NetworkPolicy and never enforces it.
  configuration_values = jsonencode({
    enableNetworkPolicy = "true"
    nodeAgent = {
      enablePolicyEventLogs = "true"
    }
  })

  tags = { Name = "${var.name_prefix}-vpc-cni" }
}

resource "aws_eks_addon" "others" {
  for_each = toset(["coredns", "kube-proxy", "eks-pod-identity-agent"])

  cluster_name  = aws_eks_cluster.this.name
  addon_name    = each.value
  addon_version = data.aws_eks_addon_version.this[each.value].version

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.this]

  tags = { Name = "${var.name_prefix}-${each.value}" }
}

resource "aws_eks_access_entry" "admin" {
  for_each = toset(var.cluster_admin_principals)

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin" {
  for_each = aws_eks_access_entry.admin

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}
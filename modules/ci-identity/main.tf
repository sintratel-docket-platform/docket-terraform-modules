locals {
  # GitHub issues the subject in immutable form, with the numeric identifier of
  # the organisation and of the repository. See AGENTS.md.
  org = "${var.github_org}@${var.github_org_id}"

  build_subjects = flatten([
    for repo in var.build_repositories : [
      for branch in var.allowed_branches :
      "repo:${local.org}/${repo}@${var.repository_ids[repo]}:ref:refs/heads/${branch}"
    ]
  ])

  infra_subjects = [
    for branch in var.allowed_branches :
    "repo:${local.org}/${var.infra_repository}@${var.repository_ids[var.infra_repository]}:ref:refs/heads/${branch}"
  ]
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = var.thumbprints

  tags = { Name = "${var.name_prefix}-github-oidc" }
}

# ---------- Build role: ECR only ----------

data "aws_iam_policy_document" "build_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.build_subjects
    }
  }
}

data "aws_iam_policy_document" "build_permissions" {
  # ECR does not allow scoping this action by resource.
  statement {
    sid       = "AutenticarContraECR"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "PublicarImagenes"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]
    resources = var.ecr_repository_arns
  }
}

resource "aws_iam_role" "build" {
  name               = "GitHubActionsBuildRole"
  description        = "Publish images to ECR from GitHub Actions"
  assume_role_policy = data.aws_iam_policy_document.build_trust.json

  tags = { Name = "GitHubActionsBuildRole" }
}

resource "aws_iam_role_policy" "build" {
  name   = "publicar-en-ecr"
  role   = aws_iam_role.build.id
  policy = data.aws_iam_policy_document.build_permissions.json
}

# ---------- Rol de infraestructura: Terraform ----------

data "aws_iam_policy_document" "deploy_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.infra_subjects
    }
  }
}

data "aws_iam_policy_document" "deploy_permissions" {
  statement {
    sid    = "AccesoAlEstadoDeTerraform"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = [var.state_bucket_arn, "${var.state_bucket_arn}/*"]
  }

  statement {
    sid    = "ProvisionarInfraestructura"
    effect = "Allow"
    actions = [
      "ec2:*",
      "eks:*",
      "ecr:*",
      "iam:*",
      "route53:*",
      "acm:*",
      "ssm:*",
      "elasticloadbalancing:*",
      "autoscaling:*",
      "logs:*",
      "kms:Describe*",
      "kms:List*",
    ]
    resources = ["*"]
  }
}

# This candidate is deliberately not attached. CloudTrail from a complete
# apply and teardown cycle must confirm the action set before the broad inline
# policy above is removed.
data "aws_iam_policy_document" "deploy_permissions_scoped_candidate" {
  statement {
    sid    = "ManageTerraformState"
    effect = "Allow"
    actions = [
      "s3:CreateBucket",
      "s3:DeleteBucket",
      "s3:DeleteObject",
      "s3:GetBucketLifecycleConfiguration",
      "s3:GetBucketLocation",
      "s3:GetBucketPolicy",
      "s3:GetBucketPublicAccessBlock",
      "s3:GetBucketTagging",
      "s3:GetBucketVersioning",
      "s3:GetEncryptionConfiguration",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutBucketLifecycleConfiguration",
      "s3:PutBucketPublicAccessBlock",
      "s3:PutBucketTagging",
      "s3:PutBucketVersioning",
      "s3:PutEncryptionConfiguration",
      "s3:PutObject",
    ]
    resources = [var.state_bucket_arn, "${var.state_bucket_arn}/*"]
  }

  statement {
    sid    = "ManageEc2Foundation"
    effect = "Allow"
    actions = [
      "ec2:AllocateAddress",
      "ec2:AssociateRouteTable",
      "ec2:AttachInternetGateway",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CreateInternetGateway",
      "ec2:CreateLaunchTemplate",
      "ec2:CreateLaunchTemplateVersion",
      "ec2:CreateNatGateway",
      "ec2:CreateRoute",
      "ec2:CreateRouteTable",
      "ec2:CreateSecurityGroup",
      "ec2:CreateSubnet",
      "ec2:CreateTags",
      "ec2:CreateVpc",
      "ec2:DeleteInternetGateway",
      "ec2:DeleteLaunchTemplate",
      "ec2:DeleteLaunchTemplateVersions",
      "ec2:DeleteNatGateway",
      "ec2:DeleteRoute",
      "ec2:DeleteRouteTable",
      "ec2:DeleteSecurityGroup",
      "ec2:DeleteSubnet",
      "ec2:DeleteTags",
      "ec2:DeleteVpc",
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeImages",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeNatGateways",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroupRules",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
      "ec2:DescribeVpcs",
      "ec2:DetachInternetGateway",
      "ec2:DisassociateRouteTable",
      "ec2:ModifyLaunchTemplate",
      "ec2:ModifySubnetAttribute",
      "ec2:ModifyVpcAttribute",
      "ec2:ReleaseAddress",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DiscoverAndCreateEksResources"
    effect = "Allow"
    actions = [
      "eks:CreateCluster",
      "eks:DescribeAddonVersions",
      "eks:ListClusters",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ManageEksResources"
    effect = "Allow"
    actions = [
      "eks:AssociateAccessPolicy",
      "eks:CreateAccessEntry",
      "eks:CreateAddon",
      "eks:CreateNodegroup",
      "eks:DeleteAccessEntry",
      "eks:DeleteAddon",
      "eks:DeleteCluster",
      "eks:DeleteNodegroup",
      "eks:DescribeAccessEntry",
      "eks:DescribeAddon",
      "eks:DescribeCluster",
      "eks:DescribeNodegroup",
      "eks:DisassociateAccessPolicy",
      "eks:ListAccessEntries",
      "eks:ListAddons",
      "eks:ListAssociatedAccessPolicies",
      "eks:ListNodegroups",
      "eks:ListTagsForResource",
      "eks:TagResource",
      "eks:UntagResource",
      "eks:UpdateAccessEntry",
      "eks:UpdateAddon",
      "eks:UpdateClusterConfig",
      "eks:UpdateClusterVersion",
      "eks:UpdateNodegroupConfig",
      "eks:UpdateNodegroupVersion",
    ]
    resources = [
      "arn:aws:eks:${var.region}:${var.account_id}:cluster/docket-*",
      "arn:aws:eks:${var.region}:${var.account_id}:nodegroup/docket-*/*/*",
      "arn:aws:eks:${var.region}:${var.account_id}:addon/docket-*/*/*",
      "arn:aws:eks:${var.region}:${var.account_id}:access-entry/docket-*/*/*/*/*",
    ]
  }

  statement {
    sid    = "ManageDocketIamResources"
    effect = "Allow"
    actions = [
      "iam:AttachRolePolicy",
      "iam:CreateOpenIDConnectProvider",
      "iam:CreatePolicy",
      "iam:CreatePolicyVersion",
      "iam:CreateRole",
      "iam:DeleteOpenIDConnectProvider",
      "iam:DeletePolicy",
      "iam:DeletePolicyVersion",
      "iam:DeleteRole",
      "iam:DeleteRolePolicy",
      "iam:DetachRolePolicy",
      "iam:GetOpenIDConnectProvider",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListOpenIDConnectProviderTags",
      "iam:ListPolicyTags",
      "iam:ListPolicyVersions",
      "iam:ListRolePolicies",
      "iam:ListRoleTags",
      "iam:PassRole",
      "iam:PutRolePolicy",
      "iam:TagOpenIDConnectProvider",
      "iam:TagPolicy",
      "iam:TagRole",
      "iam:UntagOpenIDConnectProvider",
      "iam:UntagPolicy",
      "iam:UntagRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:UpdateOpenIDConnectProviderThumbprint",
      "iam:UpdateRoleDescription",
    ]
    resources = [
      "arn:aws:iam::${var.account_id}:oidc-provider/*",
      "arn:aws:iam::${var.account_id}:policy/docket-*",
      "arn:aws:iam::${var.account_id}:policy/GitHubActionsDeployScopedCandidate",
      "arn:aws:iam::${var.account_id}:role/docket-*",
      "arn:aws:iam::${var.account_id}:role/GitHubActions*",
    ]
  }

  statement {
    sid    = "ManageDocketEcrRepositories"
    effect = "Allow"
    actions = [
      "ecr:CreateRepository",
      "ecr:DeleteLifecyclePolicy",
      "ecr:DeleteRepository",
      "ecr:DescribeRepositories",
      "ecr:GetLifecyclePolicy",
      "ecr:ListTagsForResource",
      "ecr:PutLifecyclePolicy",
      "ecr:PutImageScanningConfiguration",
      "ecr:PutImageTagMutability",
      "ecr:TagResource",
      "ecr:UntagResource",
    ]
    resources = var.ecr_repository_arns
  }

  statement {
    sid    = "ManageDocketDnsCertificatesAndParameters"
    effect = "Allow"
    actions = [
      "acm:AddTagsToCertificate",
      "acm:DeleteCertificate",
      "acm:DescribeCertificate",
      "acm:ListTagsForCertificate",
      "acm:RemoveTagsFromCertificate",
      "acm:RequestCertificate",
      "route53:ChangeResourceRecordSets",
      "route53:ChangeTagsForResource",
      "route53:CreateHostedZone",
      "route53:DeleteHostedZone",
      "route53:GetChange",
      "route53:GetHostedZone",
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResource",
      "ssm:AddTagsToResource",
      "ssm:DeleteParameter",
      "ssm:DeleteParameters",
      "ssm:DescribeParameters",
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
      "ssm:ListTagsForResource",
      "ssm:PutParameter",
      "ssm:RemoveTagsFromResource",
    ]
    resources = [
      "arn:aws:acm:${var.region}:${var.account_id}:certificate/*",
      "arn:aws:route53:::change/*",
      "arn:aws:route53:::hostedzone/*",
      "arn:aws:ssm:${var.region}:${var.account_id}:parameter/docket/*",
    ]
  }

  statement {
    sid       = "ListGlobalResources"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken", "route53:ListHostedZones"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "deploy_scoped_candidate" {
  name        = "GitHubActionsDeployScopedCandidate"
  description = "Unattached candidate for CloudTrail validation before replacing the broad deploy policy"
  policy      = data.aws_iam_policy_document.deploy_permissions_scoped_candidate.json

  tags = { Name = "GitHubActionsDeployScopedCandidate" }
}

data "aws_iam_policy_document" "plan_permissions_candidate" {
  statement {
    sid       = "ReadTerraformState"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:ListBucket"]
    resources = [var.state_bucket_arn, "${var.state_bucket_arn}/*"]
  }

  statement {
    sid       = "LockTerraformState"
    effect    = "Allow"
    actions   = ["s3:DeleteObject", "s3:PutObject"]
    resources = ["${var.state_bucket_arn}/*.tflock"]
  }

  statement {
    sid    = "ReadManagedResources"
    effect = "Allow"
    actions = [
      "acm:DescribeCertificate",
      "acm:ListCertificates",
      "acm:ListTagsForCertificate",
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeImages",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeNatGateways",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroupRules",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
      "ec2:DescribeVpcs",
      "ecr:DescribeRepositories",
      "ecr:GetLifecyclePolicy",
      "ecr:ListTagsForResource",
      "eks:DescribeAccessEntry",
      "eks:DescribeAddon",
      "eks:DescribeAddonVersions",
      "eks:DescribeCluster",
      "eks:DescribeNodegroup",
      "eks:ListAccessEntries",
      "eks:ListAddons",
      "eks:ListAssociatedAccessPolicies",
      "eks:ListClusters",
      "eks:ListNodegroups",
      "eks:ListTagsForResource",
      "iam:GetOpenIDConnectProvider",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListOpenIDConnectProviderTags",
      "iam:ListPolicyTags",
      "iam:ListPolicyVersions",
      "iam:ListRolePolicies",
      "iam:ListRoleTags",
      "route53:GetChange",
      "route53:GetHostedZone",
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResource",
      "ssm:DescribeParameters",
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
      "ssm:ListTagsForResource",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "plan_candidate" {
  name               = "GitHubActionsPlanCandidateRole"
  description        = "Unverified plan-only role candidate for GitHub Actions"
  assume_role_policy = data.aws_iam_policy_document.deploy_trust.json

  tags = { Name = "GitHubActionsPlanCandidateRole" }
}

resource "aws_iam_role_policy" "plan_candidate" {
  name   = "plan-infrastructure-candidate"
  role   = aws_iam_role.plan_candidate.id
  policy = data.aws_iam_policy_document.plan_permissions_candidate.json
}

resource "aws_iam_role" "deploy" {
  name               = "GitHubActionsDeployRole"
  description        = "Run Terraform from GitHub Actions"
  assume_role_policy = data.aws_iam_policy_document.deploy_trust.json

  tags = { Name = "GitHubActionsDeployRole" }
}

resource "aws_iam_role_policy" "deploy" {
  name   = "provisionar-infraestructura"
  role   = aws_iam_role.deploy.id
  policy = data.aws_iam_policy_document.deploy_permissions.json
}

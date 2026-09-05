locals {
  # GitHub emite el sujeto en forma inmutable, con el identificador de la
  # organizacion y el del repositorio. Ver CONVENCIONES.md.
  org = "${var.github_org}@${var.github_org_id}"

  build_subjects = flatten([
    for repo in var.build_repositories : [
      for rama in var.allowed_branches :
      "repo:${local.org}/${repo}@${var.repository_ids[repo]}:ref:refs/heads/${rama}"
    ]
  ])

  infra_subjects = [
    for rama in var.allowed_branches :
    "repo:${local.org}/${var.infra_repository}@${var.repository_ids[var.infra_repository]}:ref:refs/heads/${rama}"
  ]
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = var.thumbprints

  tags = { Name = "docket-github-oidc" }
}

# ---------- Rol de build: solo ECR ----------

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
  # ECR no admite acotar esta accion por recurso.
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
  description        = "Publicar imagenes en ECR desde GitHub Actions"
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

resource "aws_iam_role" "deploy" {
  name               = "GitHubActionsDeployRole"
  description        = "Ejecutar Terraform desde GitHub Actions"
  assume_role_policy = data.aws_iam_policy_document.deploy_trust.json

  tags = { Name = "GitHubActionsDeployRole" }
}

resource "aws_iam_role_policy" "deploy" {
  name   = "provisionar-infraestructura"
  role   = aws_iam_role.deploy.id
  policy = data.aws_iam_policy_document.deploy_permissions.json
}

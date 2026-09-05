data "aws_iam_policy_document" "trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Sin esta condicion, cualquier ServiceAccount del cluster podria asumirlo.
    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.service_account}"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.trust.json

  tags = { Name = var.role_name }
}

resource "aws_iam_role_policy" "this" {
  count = var.policy_json == "" ? 0 : 1

  name   = var.policy_name
  role   = aws_iam_role.this.id
  policy = var.policy_json
}

# Los roles creados antes de que la politica en linea fuera opcional.
moved {
  from = aws_iam_role_policy.this
  to   = aws_iam_role_policy.this[0]
}

resource "aws_iam_role_policy_attachment" "gestionadas" {
  for_each = toset(var.managed_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}
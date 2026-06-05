# AWS Secrets Manager – odpowiednik Azure Key Vault.
# Źródło sekretów (GitHub App key, tokeny) dla External Secrets Operator na EKS.
resource "aws_secretsmanager_secret" "github_app" {
  name        = "${var.name_prefix}/github-app"
  description = "GitHub App credentials dla ArgoCD / platform-apps"
}

# Rola IRSA dla External Secrets Operator – odczyt sekretów bez statycznych kluczy.
# Trust dla SA external-secrets w OBU klastrach (test + prod).
data "aws_iam_policy_document" "eso_assume" {
  dynamic "statement" {
    for_each = toset(range(length(var.oidc_provider_arns)))
    content {
      effect  = "Allow"
      actions = ["sts:AssumeRoleWithWebIdentity"]

      principals {
        type        = "Federated"
        identifiers = [var.oidc_provider_arns[statement.value]]
      }

      condition {
        test     = "StringEquals"
        variable = "${var.oidc_provider_urls[statement.value]}:sub"
        values   = ["system:serviceaccount:${var.eso_namespace}:${var.eso_service_account}"]
      }
    }
  }
}

resource "aws_iam_role" "eso" {
  name               = "${var.name_prefix}-eso-role"
  assume_role_policy = data.aws_iam_policy_document.eso_assume.json
}

data "aws_iam_policy_document" "eso_read" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = ["${aws_secretsmanager_secret.github_app.arn}*"]
  }
}

resource "aws_iam_role_policy" "eso_read" {
  name   = "${var.name_prefix}-eso-read"
  role   = aws_iam_role.eso.id
  policy = data.aws_iam_policy_document.eso_read.json
}

output "github_app_secret_arn" {
  value = aws_secretsmanager_secret.github_app.arn
}

output "eso_role_arn" {
  value = aws_iam_role.eso.arn
}

# ============================================================
# AUTO-SHUTDOWN – odpowiednik Azure Automation (codziennie 18:00)
# EventBridge Scheduler → Lambda → skalowanie node group EKS do 0.
# ============================================================

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/shutdown.py"
  output_path = "${path.module}/lambda/shutdown.zip"
}

# IAM – rola Lambdy
resource "aws_iam_role" "lambda" {
  name = "${var.name_prefix}-shutdown-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_eks" {
  name = "${var.name_prefix}-shutdown-eks"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "eks:UpdateNodegroupConfig",
        "eks:DescribeNodegroup",
        "eks:DescribeCluster",
      ]
      Resource = "*"
    }]
  })
}

resource "aws_lambda_function" "shutdown" {
  function_name    = "${var.name_prefix}-eks-shutdown"
  role             = aws_iam_role.lambda.arn
  runtime          = "python3.12"
  handler          = "shutdown.handler"
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  timeout          = 60

  environment {
    variables = {
      CLUSTER_NAMES   = join(",", var.cluster_names)
      NODE_GROUP_NAME = var.node_group_name
    }
  }
}

# Rola dla EventBridge Scheduler (wywołanie Lambdy)
resource "aws_iam_role" "scheduler" {
  name = "${var.name_prefix}-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "scheduler.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "scheduler_invoke" {
  name = "${var.name_prefix}-scheduler-invoke"
  role = aws_iam_role.scheduler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "lambda:InvokeFunction"
      Resource = aws_lambda_function.shutdown.arn
    }]
  })
}

# Harmonogram – codziennie o 18:00 (strefa Europe/Warsaw)
resource "aws_scheduler_schedule" "shutdown" {
  name = "${var.name_prefix}-eks-shutdown-18"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = var.shutdown_cron
  schedule_expression_timezone = var.schedule_timezone

  target {
    arn      = aws_lambda_function.shutdown.arn
    role_arn = aws_iam_role.scheduler.arn
  }
}

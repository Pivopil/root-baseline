locals {
  custom_authorizer_function_name = "${var.prefix}-custom-authorizer"
  custom_auth_source_path         = "${path.module}/lambda-auth-python/handlers"
}

data "archive_file" "custom_auth_index" {
  type        = "zip"
  source_dir  = local.custom_auth_source_path
  output_path = "${local.custom_auth_source_path}.zip"
}

data "aws_iam_policy_document" "lambda_sts_policy" {
  version = "2012-10-17"
  statement {
    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
  }
}

resource "aws_iam_role" "iam_role_lambda_execution_additional" {
  assume_role_policy = data.aws_iam_policy_document.lambda_sts_policy.json
}

data "aws_iam_policy_document" "iam_lambda_execution_role_policy_document" {
  version = "2012-10-17"
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_cloudwatch_log_group" "custom_authorizer_log_group" {
  name              = "/aws/lambda/${local.custom_authorizer_function_name}"
  retention_in_days = 1
}

resource "aws_iam_role" "iam_role_lambda_execution" {
  assume_role_policy = data.aws_iam_policy_document.lambda_sts_policy.json
}

resource "aws_iam_role_policy" "iam_role_lambda_execution_policy" {
  name   = "${var.prefix}-custom-auth-lambda-policy"
  role   = aws_iam_role.iam_role_lambda_execution.id
  policy = data.aws_iam_policy_document.iam_lambda_execution_role_policy_document.json
}

resource "aws_lambda_function" "custom_authorizer" {
  function_name    = local.custom_authorizer_function_name
  role             = aws_iam_role.iam_role_lambda_execution.arn
  runtime          = "python3.7"
  timeout          = 30
  handler          = "authorizer.auth"
  filename         = "${local.custom_auth_source_path}.zip"
  source_code_hash = data.archive_file.custom_auth_index.output_base64sha256
  environment {
    variables = {
      token = var.custom_authorizer_token
    }
  }
}

variable "custom_authorizer_token" {
}

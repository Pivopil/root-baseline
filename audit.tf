variable "organization" {
}

variable "root_workspace" {
}

variable "terraform_hostname" {
}

data "terraform_remote_state" "awsdevbot_root_baseline" {
  backend = "remote"
  config = {
    hostname     = var.terraform_hostname
    organization = var.organization
    workspaces = {
      name = var.root_workspace
    }
  }
}

locals {
  add_subscription_function_name        = "${var.prefix}-AddSubscriptionLambda"
  add_subscription_function_source_path = "${path.module}/lambda-log-centralizer/handlers"
}

data "archive_file" "AddSubscriptionLambdaSourceCode" {
  type        = "zip"
  source_dir  = local.add_subscription_function_source_path
  output_path = "${local.add_subscription_function_source_path}.zip"
}

data "aws_iam_policy_document" "AddSubscriptionFilterRole_sts_policy" {
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

resource "aws_iam_role" "AddSubscriptionFilterRole" {
  name               = "${var.prefix}-AddSubscriptionFilterRole"
  assume_role_policy = data.aws_iam_policy_document.AddSubscriptionFilterRole_sts_policy.json
}

resource "aws_iam_role_policy_attachment" "AddSubscriptionFilterRole_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ])

  policy_arn = each.key
  role       = aws_iam_role.AddSubscriptionFilterRole.name
}

data "aws_iam_policy_document" "AddSubcriptionPolicy_policy_document" {
  version = "2012-10-17"
  statement {
    effect    = "Allow"
    actions   = ["logs:*", "ssm:GetParameter"]
    resources = ["*"]
  }
}

resource "aws_cloudwatch_log_group" "add_subscription_function_log_group" {
  name              = "/aws/lambda/${local.add_subscription_function_name}"
  retention_in_days = 1
}

resource "aws_iam_role_policy" "AddSubscriptionLambda_execution_policy" {
  name   = "${var.prefix}-AddSubscriptionLambdaPolicy"
  role   = aws_iam_role.AddSubscriptionFilterRole.id
  policy = data.aws_iam_policy_document.AddSubcriptionPolicy_policy_document.json
}

resource "aws_cloudwatch_event_rule" "CreateLogGroupEvent" {
  event_pattern = jsonencode({
    "source" : ["aws.logs"],
    "detail-type" : ["AWS API Call via CloudTrail"],
    "detail" : { "eventSource" : ["logs.amazonaws.com"],
      "eventName" : ["CreateLogGroup"]
  } })
  name       = "${var.prefix}-CreateLogGroupEvent"
  is_enabled = true
}

resource "aws_cloudwatch_event_target" "CreateLogGroupEvent_target" {
  target_id = "add_new_subscription"
  arn       = aws_lambda_function.AddSubscriptionLambda.arn
  rule      = aws_cloudwatch_event_rule.CreateLogGroupEvent.name
}

resource "aws_lambda_permission" "AddSubscriptionLambdaPermission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.AddSubscriptionLambda.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.CreateLogGroupEvent.arn
}

resource "aws_lambda_function" "AddSubscriptionLambda" {
  function_name    = local.add_subscription_function_name
  role             = aws_iam_role.AddSubscriptionFilterRole.arn
  runtime          = "python3.7"
  timeout          = 30
  handler          = "lambda.lambda_handler"
  filename         = "${local.add_subscription_function_source_path}.zip"
  source_code_hash = data.archive_file.AddSubscriptionLambdaSourceCode.output_base64sha256
  environment {
    variables = {
      audit_destination_arn = data.terraform_remote_state.awsdevbot_root_baseline.outputs.audit_destination_arn
    }
  }
}

resource "aws_cloudwatch_log_group" "TestSubscriptionEventLogGroup" {
  name = "TestSubscriptionEventLogGroup"
}

locals {
  step_function_lambda_source_dir          = "${path.module}/lambda-step-function/handlers"
  step_function_lambda_sources_output_path = "${local.step_function_lambda_source_dir}.zip"
}

data "archive_file" "step_function_source" {
  type        = "zip"
  source_dir  = local.step_function_lambda_source_dir
  output_path = local.step_function_lambda_sources_output_path
}

resource "aws_iam_role" "step_function_lambda_execution_role" {
  name = "${var.prefix}-step_function_lambda_execution_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "sqs_receive_message_policy" {
  name   = "${var.prefix}-sqs_receive_message_policy"
  policy = data.aws_iam_policy_document.sqs_receive_message_policy_document.json
}

data "aws_iam_policy_document" "sqs_receive_message_policy_document" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ChangeMessageVisibility"
    ]
    resources = [
      aws_sqs_queue.sqs_queue.arn
    ]
  }
}

resource "aws_iam_policy" "cloud_watch_logs_policy" {
  name   = "${var.prefix}-cloud_watch_logs_policy"
  policy = data.aws_iam_policy_document.cloud_watch_logs_policy_document.json
}

data "aws_iam_policy_document" "cloud_watch_logs_policy_document" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "states_execution_policy" {
  name   = "${var.prefix}-states_execution_policy"
  policy = data.aws_iam_policy_document.StatesExecutionPolicyDocument.json
}

data "aws_iam_policy_document" "StatesExecutionPolicyDocument" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "states:SendTaskSuccess",
      "states:SendTaskFailure"
    ]
    resources = [
      aws_sfn_state_machine.wait_for_callback_state_machine.arn
    ]
  }
}

resource "aws_iam_role_policy_attachment" "SQSReceiveMessagePolicy-LambdaExecutionRole-attach" {
  policy_arn = aws_iam_policy.sqs_receive_message_policy.arn
  role       = aws_iam_role.step_function_lambda_execution_role.name
}

resource "aws_iam_role_policy_attachment" "CloudWatchLogsPolicy-LambdaExecutionRole-attach" {
  policy_arn = aws_iam_policy.cloud_watch_logs_policy.arn
  role       = aws_iam_role.step_function_lambda_execution_role.name
}

resource "aws_iam_role_policy_attachment" "StatesExecutionPolicy-LambdaExecutionRole-attach" {
  policy_arn = aws_iam_policy.states_execution_policy.arn
  role       = aws_iam_role.step_function_lambda_execution_role.name
}

resource "aws_iam_role_policy_attachment" "AWSLambdaExecute" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AWSLambdaExecute",
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AmazonSSMAutomationRole"
  ])

  policy_arn = each.key
  role       = aws_iam_role.step_function_lambda_execution_role.name
}

resource "aws_iam_role" "states_execution_role" {
  name               = "${var.prefix}-states_execution_role"
  path               = "/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "states.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "sns_publish_policy" {
  name   = "${var.prefix}-sns_publish_policy"
  policy = data.aws_iam_policy_document.sns_publish_policy_document.json
}

data "aws_iam_policy_document" "sns_publish_policy_document" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]
    resources = [
      aws_sns_topic.sns_topic.arn
    ]
  }
}

resource "aws_iam_policy" "sqs_send_message_policy" {
  name   = "${var.prefix}-sqs_send_message_policy"
  policy = data.aws_iam_policy_document.sqs_send_message_policy_document.json
}

data "aws_iam_policy_document" "sqs_send_message_policy_document" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "sqs:SendMessage"
    ]
    resources = [
      aws_sqs_queue.sqs_queue.arn
    ]
  }
}

resource "aws_iam_policy" "invoke_lambda_policy" {
  name   = "${var.prefix}-invoke_lambda_policy"
  policy = data.aws_iam_policy_document.invoke_lambda_policy_document.json
}

data "aws_iam_policy_document" "invoke_lambda_policy_document" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [
      aws_lambda_function.start_automation_lambda.arn
    ]
  }
}

resource "aws_iam_role_policy_attachment" "sns_publish_policy_attach" {
  policy_arn = aws_iam_policy.sns_publish_policy.arn
  role       = aws_iam_role.states_execution_role.name
}

resource "aws_iam_role_policy_attachment" "sqs_send_message_policy_attach" {
  policy_arn = aws_iam_policy.sqs_send_message_policy.arn
  role       = aws_iam_role.states_execution_role.name
}

resource "aws_iam_role_policy_attachment" "invoke_lambda_policy_attach" {
  policy_arn = aws_iam_policy.invoke_lambda_policy.arn
  role       = aws_iam_role.states_execution_role.name
}

//==

resource "aws_sqs_queue" "sqs_queue_dlq" {
  delay_seconds              = 0
  visibility_timeout_seconds = 30
}

resource "aws_sqs_queue" "sqs_queue" {
  delay_seconds              = 0
  visibility_timeout_seconds = 30
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.sqs_queue_dlq.arn
    maxReceiveCount     = 30
  })
}

resource "aws_sns_topic" "sns_topic" {
  display_name = "${var.prefix}-sns_topic_callback_topic"
}

resource "aws_lambda_event_source_mapping" "LambdaFunctionEventSourceMapping" {
  event_source_arn = aws_sqs_queue.sqs_queue.arn
  function_name    = aws_lambda_function.callback_with_task_token.arn
  batch_size       = 1
  enabled          = true
}

resource "aws_lambda_function" "callback_with_task_token" {
  function_name    = "${var.prefix}-callback_with_task_token"
  handler          = "check-ssm-execution.handler"
  role             = aws_iam_role.step_function_lambda_execution_role.arn
  runtime          = "nodejs12.x"
  filename         = local.step_function_lambda_sources_output_path
  source_code_hash = data.archive_file.step_function_source.output_base64sha256
}

resource "aws_lambda_function" "start_automation_lambda" {
  function_name    = "${var.prefix}-start_automation_lambda"
  handler          = "start-ssm.handler"
  role             = aws_iam_role.step_function_lambda_execution_role.arn
  runtime          = "nodejs12.x"
  filename         = local.step_function_lambda_sources_output_path
  source_code_hash = data.archive_file.step_function_source.output_base64sha256
}

//=== State Machine

resource "aws_sfn_state_machine" "wait_for_callback_state_machine" {
  name     = "${var.prefix}-wait_for_callback_state_machine"
  role_arn = aws_iam_role.states_execution_role.arn

  definition = <<EOF
{
  "Comment": "Step Function Template",
  "StartAt": "Start SSM",
  "States": {
    "Start SSM": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.start_automation_lambda.arn}",
      "InputPath": "$",
      "ResultPath": "$",
      "Next": "Wait For Callback",
      "Catch": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "Next": "Notify Failure"
        }
      ]
    },
    "Wait For Callback": {
      "Type": "Task",
      "Resource": "arn:aws:states:::sqs:sendMessage.waitForTaskToken",
      "Parameters": {
        "QueueUrl": "${aws_sqs_queue.sqs_queue.id}",
        "MessageBody": {
          "MessageTitle": "Waiting for callback with task token.",
          "Context.$": "$",
          "TaskToken.$": "$$.Task.Token"
        }
      },
      "Next": "Notify Success",
      "Catch": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "Next": "Notify Failure"
        }
      ]
    },
    "Notify Success": {
      "Type": "Task",
      "Resource": "arn:aws:states:::sns:publish",
      "Parameters": {
        "Message": "Callback received. Task started by Step Functions succeeded.",
        "TopicArn": "${aws_sns_topic.sns_topic.arn}"
      },
      "End": true
    },
    "Notify Failure": {
      "Type": "Task",
      "Resource": "arn:aws:states:::sns:publish",
      "Parameters": {
        "Message": "Task started by Step Functions failed.",
        "TopicArn": "${aws_sns_topic.sns_topic.arn}"
      },
      "End": true
    }
  }
}
EOF
}

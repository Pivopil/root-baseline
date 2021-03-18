// route 53 logs, only for us-east-1 region
//https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_query_log

resource "aws_cloudwatch_log_group" "aws_route53_domain" {
  name              = "/aws/route53/${data.aws_route53_zone.public.name}"
  retention_in_days = 30
}

# Example CloudWatch log resource policy to allow Route53 to write logs
# to any log group under /aws/route53/*

data "aws_iam_policy_document" "route53_query_loggin_policy" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["arn:aws:logs:*:*:log-group:/aws/route53/*"]

    principals {
      identifiers = ["route53.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "route53_query_logging_policy" {
  policy_document = data.aws_iam_policy_document.route53_query_loggin_policy.json
  policy_name     = "${var.prefix}-route53-query-logging-policy"
}

# Example Route53 zone with query logging

resource "aws_route53_query_log" "domain" {
  depends_on = [aws_cloudwatch_log_resource_policy.route53_query_logging_policy]

  cloudwatch_log_group_arn = aws_cloudwatch_log_group.aws_route53_domain.arn
  zone_id                  = data.aws_route53_zone.public.zone_id
}


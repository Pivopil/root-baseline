//data "archive_file" "index" {
//  type        = "zip"
//  source_dir  = "${path.module}/lambda/handlers"
//  output_path = "${path.module}/lambda/handlers.zip"
//}
//
////https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function
//resource "aws_lambda_function" "alb_function" {
//  function_name    = "${var.prefix}-elb-function"
//  role             = aws_iam_role.iam_role_alb_function.arn
//  runtime          = "nodejs12.x"
//  timeout          = 30
//  handler          = "index.handler"
//  filename         = "${path.module}/lambda/handlers.zip"
//  source_code_hash = data.archive_file.index.output_base64sha256
//}
//
////https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document
//data "aws_iam_policy_document" "iam_role_alb_function_policy" {
//  version = "2012-10-17"
//  statement {
//    actions = ["sts:AssumeRole"]
//    effect  = "Allow"
//    principals {
//      identifiers = ["lambda.amazonaws.com"]
//      type        = "Service"
//    }
//  }
//}
//
////https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function
//resource "aws_iam_role" "iam_role_alb_function" {
//  name               = "${var.prefix}-alb-role"
//  assume_role_policy = data.aws_iam_policy_document.iam_role_alb_function_policy.json
//}
//
//resource "aws_iam_role_policy_attachment" "elb_function_policies" {
//  for_each = toset([
//    "arn:aws:iam::aws:policy/AWSLambdaExecute",
//    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
//    "arn:aws:iam::aws:policy/AutoScalingReadOnlyAccess",
//  ])
//
//  policy_arn = each.key
//  role       = aws_iam_role.iam_role_alb_function.name
//}
//
//resource "aws_lambda_permission" "alb_lambda_permission" {
//  statement_id  = "AllowExecutionFromApplicationLodaBallancer"
//  action        = "lambda:InvokeFunction"
//  function_name = aws_lambda_function.alb_function.arn
//  principal     = "elasticloadbalancing.amazonaws.com"
//  source_arn    = aws_lb_target_group.alb_lb_target_group.arn
//}
//
//
//
////https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-type
//resource "aws_lb_target_group" "alb_lb_target_group" {
//  name        = "${var.prefix}-alb-tg"
//  target_type = "lambda"
//}
//
//resource "aws_lb_target_group_attachment" "alb_tg_lambda_attachment" {
//  target_group_arn = aws_lb_target_group.alb_lb_target_group.arn
//  target_id        = aws_lambda_function.alb_function.arn
//  depends_on       = [aws_lambda_permission.alb_lambda_permission]
//}
//
//resource "aws_lb" "alb_lambda" {
//  name               = "${var.prefix}-lb"
//  internal           = false
//  load_balancer_type = "application"
//  security_groups    = [aws_security_group.alb_sg.id]
//
//  access_logs {
//    bucket  = data.terraform_remote_state.awsdevbot_root_baseline.outputs.audit_bucket
//    prefix  = "${var.prefix}-alb_lambda"
//    enabled = true
//  }
//}
//
//resource "aws_lb_listener" "alb_listener" {
//  load_balancer_arn = aws_lb.alb_lambda.arn
//  port              = 443
//  protocol          = "HTTPS"
//  default_action {
//    type             = "forward"
//    target_group_arn = aws_lb_target_group.alb_lb_target_group.arn
//  }
//  certificate_arn = module.acm.this_acm_certificate_arn
//}
//
//resource "aws_route53_record" "alb_route53_record" {
//  zone_id = data.aws_route53_zone.public.zone_id
//  name    = "alb.${var.public_subdomain}"
//  type    = "A"
//
//  alias {
//    name                   = aws_lb.alb_lambda.dns_name
//    zone_id                = aws_lb.alb_lambda.zone_id
//    evaluate_target_health = false
//  }
//}

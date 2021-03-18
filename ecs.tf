resource "aws_ecs_cluster" "fargate_cluster" {
  name = local.aws_ecs_cluster_name
}

locals {
  ecs_prefix           = "${var.prefix}-ecs"
  aws_ecs_cluster_name = "${var.prefix}-fargate-cluster"
}

// https://docs.aws.amazon.com/elasticloadbalancing/latest/userguide/what-is-load-balancing.html
// https://www.terraform.io/docs/providers/aws/r/lb.html
resource "aws_alb" "ecs_cluster_alb" {
  name            = "${local.ecs_prefix}-alb"
  internal        = false
  security_groups = [aws_security_group.alb_sg.id]
  subnets         = tolist(data.aws_subnet_ids.default_subtets.ids)

  access_logs {
    bucket  = data.terraform_remote_state.awsdevbot_root_baseline.outputs.audit_bucket
    prefix  = "${var.prefix}-alb_logs"
    enabled = true
  }
}

//https://www.terraform.io/docs/providers/aws/r/lb_listener.html
resource "aws_alb_listener" "ecs_alb_https_listener" {
  load_balancer_arn = aws_alb.ecs_cluster_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = module.acm.this_acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.ecs_default_target_group.arn
  }

  depends_on = [
    aws_alb_target_group.ecs_default_target_group,
    aws_alb.ecs_cluster_alb
  ]
}

// https://www.terraform.io/docs/providers/aws/r/lb_target_group.html
// https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html
resource "aws_alb_target_group" "ecs_default_target_group" {
  name       = "${local.ecs_prefix}-tg"
  port       = 80
  protocol   = "HTTP"
  vpc_id     = aws_default_vpc.default.id
  depends_on = [aws_alb.ecs_cluster_alb]
}

// https://www.terraform.io/docs/providers/aws/r/route53_record.html
resource "aws_route53_record" "ecs_load_balancer_record" {
  name    = "*.ecs.${var.public_subdomain}"
  type    = "A"
  zone_id = data.aws_route53_zone.public.zone_id

  alias {
    evaluate_target_health = false
    name                   = aws_alb.ecs_cluster_alb.dns_name
    zone_id                = aws_alb.ecs_cluster_alb.zone_id
  }
  depends_on = [
    aws_alb.ecs_cluster_alb
  ]
}

resource "aws_iam_role" "ecs_cluster_role" {
  name               = "${local.ecs_prefix}-IAM-Role"
  assume_role_policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
  {
    "Effect": "Allow",
    "Principal": {
      "Service": ["ecs.amazonaws.com", "ec2.amazonaws.com", "application-autoscaling.amazonaws.com"]
    },
    "Action": "sts:AssumeRole"
  }
  ]
}
EOF

}

resource "aws_iam_role_policy" "ecs_cluster_policy" {
  name   = "${local.ecs_prefix}-IAM-Policy"
  role   = aws_iam_role.ecs_cluster_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:*",
        "ec2:*",
        "elasticloadbalancing:*",
        "ecr:*",
        "dynamodb:*",
        "cloudwatch:*",
        "s3:*",
        "rds:*",
        "sqs:*",
        "sns:*",
        "logs:*",
        "ssm:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF

}

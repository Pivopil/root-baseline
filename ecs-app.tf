// Terraform way to populate template file with terraform variables
data "template_file" "ecs_task_definition_template" {
  template = file("ecs-app/task_definition.json")

  vars = {
    task_definition_name  = var.ecs_service_name
    ecs_service_name      = var.ecs_service_name
    docker_image_url      = var.docker_image_url
    memory                = var.memory
    docker_container_port = var.docker_container_port
    spring_profile        = var.spring_profile
    region                = data.aws_region.current.id
  }
}

//
resource "aws_ecs_task_definition" "springbootapp-task-definition" {
  // Template file with rendered variables
  container_definitions = data.template_file.ecs_task_definition_template.rendered
  // Just ecs service name
  family = var.ecs_service_name
  cpu    = 512
  memory = var.memory
  // Set FarGate as a target way to manage ECS
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  // Let Fargete Task to use AWS resourses
  execution_role_arn = aws_iam_role.fargate_iam_role.arn
  task_role_arn      = aws_iam_role.fargate_iam_role.arn
}

resource "aws_iam_role" "fargate_iam_role" {
  name               = "${var.ecs_service_name}-IAM-Role"
  assume_role_policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
  {
    "Effect": "Allow",
    "Principal": {
      "Service": ["ecs.amazonaws.com", "ecs-tasks.amazonaws.com"]
    },
    "Action": "sts:AssumeRole"
  }
  ]
}
EOF

}

resource "aws_iam_role_policy" "fargate_iam_role_policy" {
  name = "${var.ecs_service_name}-IAM-Role-Policy"
  role = aws_iam_role.fargate_iam_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:*",
        "ecr:*",
        "logs:*",
        "cloudwatch:*",
        "elasticloadbalancing:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF

}

// control traffic between containert in ECS to the external internet
resource "aws_security_group" "app_security_group" {
  name        = "${var.ecs_service_name}-SG"
  description = "Security group for springbootapp to communicate in and out"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    from_port   = 8080
    protocol    = "TCP"
    to_port     = 8080
    cidr_blocks = [aws_default_vpc.default.cidr_block]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.ecs_service_name}-SG"
  }
}

resource "aws_alb_target_group" "ecs_app_target_group" {
  name        = "${var.ecs_service_name}-TG"
  port        = var.docker_container_port
  protocol    = "HTTP"
  vpc_id      = aws_default_vpc.default.id
  target_type = "ip"

  // ECS could undestand that my apps are healthy
  health_check {
    // check any helthcheck endpoin
    path     = "/actuator/health"
    protocol = "HTTP"
    matcher  = "200"
    interval = 60
    timeout  = 30
    // number of retries
    unhealthy_threshold = "3"
    healthy_threshold   = "3"
  }

  tags = {
    Name = "${var.ecs_service_name}-TG"
  }
  depends_on = [
    aws_alb.ecs_cluster_alb
  ]
}

resource "aws_ecs_service" "ecs_service" {
  name            = var.ecs_service_name
  task_definition = var.ecs_service_name
  desired_count   = var.desired_task_number

  // Consume hardvare and network resourses
  cluster     = local.aws_ecs_cluster_name
  launch_type = "FARGATE"

  network_configuration {
    // Public subnets to enable public ip a
    subnets         = data.aws_subnet_ids.default_subtets.ids
    security_groups = [aws_security_group.app_security_group.id]
    // Public ip address
    assign_public_ip = true
  }

  load_balancer {
    container_name = var.ecs_service_name
    // docker container port
    container_port   = var.docker_container_port
    target_group_arn = aws_alb_target_group.ecs_app_target_group.arn
  }

}

// Taget group -> LB relation with some listener configuration
resource "aws_alb_listener_rule" "ecs_alb_listener_rule" {
  listener_arn = aws_alb_listener.ecs_alb_https_listener.arn

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.ecs_app_target_group.arn
  }

  condition {
    host_header {
      values = ["${lower(var.ecs_service_name)}.ecs.${var.public_subdomain}"]
    }
  }
}

resource "aws_cloudwatch_log_group" "springbootapp_log_group" {
  name = "${var.ecs_service_name}-LogGroup"
}

variable "ecs_service_name" {
  default = "springbootapp"
}

variable "docker_image_url" {
}

variable "memory" {
  default = 1024
}

variable "docker_container_port" {
  default = 8080
}

variable "spring_profile" {
  default = "default"
}

variable "desired_task_number" {
  default = 2
}

//data "aws_ami" "ubuntu_latest" {
//  most_recent = true
//  owners      = [var.aws_ami_owner]
//  name_regex  = var.aws_ami_name_regex
//
//  filter {
//    name   = "root-device-type"
//    values = ["ebs"]
//  }
//
//  filter {
//    name   = "virtualization-type"
//    values = ["hvm"]
//  }
//}
//
//
//locals {
//  user_arn_elements = split("/", data.aws_caller_identity.current.arn)
//  username          = element(local.user_arn_elements, length(local.user_arn_elements) - 1)
//  user_data         = <<EOF
//#!/bin/bash
//sudo apt update
//sudo apt install -y mysql-server awscli
//cd /tmp
//wget https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem
//EOF
//}
//
//data "aws_iam_policy_document" "instance_assume_role_policy" {
//  version = "2012-10-17"
//  statement {
//    actions = ["sts:AssumeRole"]
//    effect  = "Allow"
//    principals {
//      type        = "Service"
//      identifiers = ["ec2.amazonaws.com"]
//    }
//  }
//}
//
//resource "aws_iam_role_policy_attachment" "instance_role_attachment" {
//  for_each = toset([
//    "arn:aws:iam::aws:policy/AmazonRDSFullAccess",
//    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
//  ])
//
//  policy_arn = each.key
//  role       = aws_iam_role.ssm_rds_instance_role.name
//}
//
//resource "aws_iam_role" "ssm_rds_instance_role" {
//  name               = "${var.prefix}-ssm_instance_role"
//  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json
//}
//
//resource "aws_iam_instance_profile" "iam_instance_profile" {
//  name = "${var.prefix}-iam_instance_profile"
//  role = aws_iam_role.ssm_rds_instance_role.name
//}
//
//module "ec2" {
//  source         = "terraform-aws-modules/ec2-instance/aws"
//  version        = "2.16.0"
//  instance_count = var.instance_count
//
//  name                        = "${var.prefix}-app-instance"
//  ami                         = data.aws_ami.ubuntu_latest.id
//  instance_type               = var.instance_type
//  cpu_credits                 = var.cpu_credits
//  subnet_id                   = tolist(data.aws_subnet_ids.default_subtets.ids)[0]
//  vpc_security_group_ids      = [data.aws_security_group.default.id]
//  associate_public_ip_address = var.associate_public_ip_address
//  iam_instance_profile        = aws_iam_instance_profile.iam_instance_profile.name
//  user_data_base64            = base64encode(local.user_data)
//  //  tags = {
//  //    env : var.prefix
//  //    Owner : local.username
//  //  }
//  //  volume_tags = {
//  //    env : var.prefix
//  //    Owner : local.username
//  //  }
//}
//
//variable "ami" {
//  default = null
//}
//
//variable "cpu_credits" {
//  description = "The credit option for CPU usage (unlimited or standard)"
//  type        = string
//  default     = "standard"
//}
//
//variable "instance_type" {
//  description = "The type of instance to start"
//  type        = string
//  default     = "t2.micro"
//}
//
//variable "associate_public_ip_address" {
//  description = "If true, the EC2 instance will have associated public IP address"
//  type        = bool
//  default     = true
//}
//
//variable "aws_ami_owner" {
//  description = "AMI owner id"
//  type        = string
//  default     = "099720109477"
//}
//variable "aws_ami_name_regex" {
//  description = "AMI name regex"
//  type        = string
//  default     = "^.*ubuntu-bionic-18.04-amd64-server.*$"
//}
//
//variable "instance_count" {
//  description = "Number of instances to launch"
//  type        = number
//  default     = 1
//}
//
//variable "vpc_id" {
//  description = "VPC id like 'vpc-017f827c'"
//  type        = string
//  default     = null
//}
//
//resource "aws_ssm_document" "sleep" {
//  name            = "${var.prefix}_sleep"
//  document_type   = "Automation"
//  document_format = "YAML"
//
//  content = <<DOC
//    description: Simple demo ssm document
//    schemaVersion: '0.3'
//    mainSteps:
//      - action: 'aws:runCommand'
//        name: sleep
//        inputs:
//          DocumentName: AWS-RunShellScript
//          Parameters:
//            commands:
//              - sleep 55s
//          Targets:
//            - Key: 'tag:Name'
//              Values:
//                - "${var.prefix}-app-instance"
//DOC
//}

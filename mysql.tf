resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

locals {
  admin_username = "root"
  database_name  = "master_db"
}

resource "aws_secretsmanager_secret" "rds_credentials" {
  name                    = "${var.prefix}-rds-credentials"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "develop_iam_user_keys_version" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    admin_password = random_password.password.result
    admin_username = local.admin_username
    database_name  = local.database_name
  })
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "2.20.0"

  identifier = "${var.prefix}-rds"

  family               = var.family
  major_engine_version = var.major_engine_version
  engine               = var.engine
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  allocated_storage    = var.allocated_storage

  name     = local.database_name
  username = local.admin_username
  password = random_password.password.result
  port     = var.port

  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  vpc_security_group_ids = [data.aws_security_group.default.id]
  subnet_ids             = tolist(data.aws_subnet_ids.default_subtets.ids)

  maintenance_window      = var.maintenance_window
  backup_window           = var.backup_window
  backup_retention_period = var.backup_retention_period
  copy_tags_to_snapshot   = var.copy_tags_to_snapshot

}

resource "aws_route53_record" "database" {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = "rds.${var.public_subdomain}"
  type    = "CNAME"
  ttl     = "300"
  records = [module.db.this_db_instance_address]
}

variable "iam_database_authentication_enabled" {
  description = "Specifies whether or mappings of AWS Identity and Access Management (IAM) accounts to database accounts is enabled https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.IAMDBAuth.html"
  type        = bool
  default     = true
}

variable "copy_tags_to_snapshot" {
  description = "On delete, copy all Instance tags to the final snapshot (if final_snapshot_identifier is specified)"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "The days to retain backups for"
  type        = number
  default     = 0
}

variable "backup_window" {
  description = "The daily time range (in UTC) during which automated backups are created if they are enabled. Example: '09:46-10:16'. Must not overlap with maintenance_window"
  type        = string
  default     = "03:00-06:00"
}

variable "maintenance_window" {
  description = "The window to perform maintenance in. Syntax: 'ddd:hh24:mi-ddd:hh24:mi'. Eg: 'Mon:00:00-Mon:03:00'"
  type        = string
  default     = "Mon:00:00-Mon:03:00"
}

variable "port" {
  description = "The port on which the DB accepts connections"
  type        = string
  default     = "3306"
}

variable "allocated_storage" {
  description = "The allocated storage in gigabytes"
  type        = string
  default     = "20"
}

variable "instance_class" {
  description = "The instance type of the RDS instance"
  type        = string
  default     = "db.t2.micro"
}

variable "engine" {
  description = "The database engine to use"
  type        = string
  default     = "mysql"
}

variable "engine_version" {
  description = "The engine version to use"
  type        = string
  default     = "5.7.28"
}

variable "major_engine_version" {
  description = "Specifies the major version of the engine that this option group should be associated with"
  type        = string
  default     = "5.7"
}

variable "family" {
  description = "The family of the DB parameter group"
  type        = string
  default     = "mysql5.7"
}

locals {
  tag_region = data.aws_region.current.name
  tag_aws_account_id = data.aws_caller_identity.current.account_id
}


module "custom_tags" {
  // git::https://github.com/Pivopil/awsdevbot-app.git//modules/tags?ref=main
  source = "./modules/tags"

  prefix                    = var.prefix
  app_env_name              = var.public_subdomain
  app_env_version           = "0.0.1"
  app_env_component_name    = var.public_subdomain
  app_env_component_version = "0.0.1"
  support_email             = "example@suport.com"
  owner                     = "arn:aws:sts::${local.tag_aws_account_id}:assumed-role/OrganizationAccountAccessRole"
  is_temp                   = true
  expires_at                = timeadd("2021-11-22T00:00:00Z", "720h")
  deploy_tool               = "terraform 14.5"
  vcs                       = "github.com/Pivopil/root-baseline"
  backup_enabled            = false
  aws_account_id            = local.tag_aws_account_id
  company                   = var.public_subdomain
  compliance                = "GDPR"
  data_sensitivity          = "Public"
  encryption                = true
  public_facing             = true
  region                    = local.tag_region
  backup_config             = "no-backup"
}

variable "workspace" {
}

// https://d1.awsstatic.com/whitepapers/aws-tagging-best-practices.pdf
// todo: add validation to tags
// Member must satisfy regular expression pattern: [\p{L}\p{Z}\p{N}_.:\/=+\-@]*
locals {
  keys = compact([
    "app:env",
    "app:version",
    "app:component:name",
    "app:component:version",
    "support:email",
    "owner",
    "automation:temp:enabled:bool",
    "automation:temp:expires:date",
    "operation:deploy:tool",
    "operation:vcs",
    "operation:backup:enabled:bool",
    "operation:backup:config:json",
    "aws:account:id",
    "company",
    "aws:region",
    "security:compliance",
    "security:data:sensitivity",
    "security:data:encryption",
    "security:public:facing"
  ])
  values = compact([
    var.app_env_name,
    var.app_env_version,
    var.app_env_component_name,
    var.app_env_component_version,
    var.support_email,
    var.owner,
    var.is_temp,
    var.expires_at,
    var.deploy_tool,
    var.vcs,
    var.backup_enabled,
    var.backup_config,
    var.aws_account_id,
    var.company,
    var.region,
    var.compliance,
    var.data_sensitivity,
    var.encryption,
    var.public_facing
  ])
  tags = zipmap(local.keys, local.values)
}

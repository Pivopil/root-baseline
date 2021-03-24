variable "prefix" {
  type = string
}

variable "app_env_name" {
  type = string
}
variable "app_env_version" {
  type = string
  description = "https://semver.org"
}

variable "app_env_component_version" {
  type = string
}

variable "app_env_component_name" {
  type = string
}

variable "support_email" {
  type = string
}

variable "owner" {
  type = string
}
variable "is_temp" {
  type = bool
  default = false
}
variable "expires_at" {
  type = string
  description = "expires at date"
  default = "never"
}

variable "deploy_tool" {
  default = "terraform14.5"
}

variable "vcs" {
  default = "github.com/Pivolil"
}

variable "backup_enabled" {
  type = bool
  default = false
}

variable "backup_config" {
  type = object({})
  default = {}
}

variable "aws_account_id" {
  type = string
}

variable "company" {
  type = string
}

variable "region" {
  type = string
}

variable "compliance" {
  type = string
}

variable "public_facing" {
  type = bool
}

variable "encryption" {
  type = bool
}

variable "data_sensitivity" {
  type = string
}

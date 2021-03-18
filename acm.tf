data "aws_route53_zone" "public" {
  name         = var.public_subdomain
  private_zone = false
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "2.12.0"

  create_certificate = true
  domain_name        = var.public_subdomain
  zone_id            = data.aws_route53_zone.public.zone_id
  subject_alternative_names = [
    "api.${var.public_subdomain}",
    "www.${var.public_subdomain}",
    "app.${var.public_subdomain}",
    "alb.${var.public_subdomain}",
    "ecs.${var.public_subdomain}",
    "*.ecs.${var.public_subdomain}"
  ]
  tags = {
    Name = var.public_subdomain
  }
}

variable "public_subdomain" {
  default = ""
}

output "aws_caller_identity" {
  value = data.aws_caller_identity.current
}

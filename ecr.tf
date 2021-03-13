resource "aws_s3_bucket" "artifact_bucket" {
  force_destroy = true
}

resource "aws_ecr_repository" "springboot_ecr_repository" {
  name = "springbootapp"
}

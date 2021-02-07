provider "aws" {
  assume_role {
    role_arn = var.develop_assume_role
  }
}

resource "aws_s3_bucket" "develop_test_bucket" {
  bucket = var.bucket_name
}

variable "bucket_name" {
  type = string
}

variable "develop_assume_role" {
  type = string
}

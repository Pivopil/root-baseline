//https://github.com/aws-samples/aws-ecs-cicd-terraform/blob/master/terraform/codebuild.tf
data "aws_iam_policy_document" "codebuild_role_document" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codebuild_role" {
  name = "${var.prefix}-codebuild_role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_role_document.json
}

data "aws_iam_policy_document" "codebuild_policy_document" {
  version = "2012-10-17"
  statement {
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents", "ecr:GetAuthorizationToken"]
    effect    = "Allow"
    resources = ["*"]
  }
  statement {
    actions   = ["s3:GetObject", "s3:GetObjectVersion", "s3:PutObject"]
    effect    = "Allow"
    resources = ["${aws_s3_bucket.artifact_bucket.arn}/*"]
  }
  statement {
    actions = ["ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability", "ecr:PutImage",
      "ecr:InitiateLayerUpload", "ecr:UploadLayerPart",
    "ecr:CompleteLayerUpload"]
    effect    = "Allow"
    resources = ["*"]
// todo: add specific resources like [aws_ecr_repository.springboot_ecr_repository.arn, arn:aws:ecr:REGION:ACCOUNT_ID:repository/openjdk]
  }
  statement {
    actions = ["ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    "ecr:BatchCheckLayerAvailability"]
    effect    = "Allow"
    resources = [aws_ecr_repository.springboot_ecr_repository.arn]
  }
}

resource "aws_s3_bucket" "artifact_bucket" {
}

resource "aws_iam_policy" "codebuild_policy" {
  description = "Policy to allow codebuild to execute build spec"
  policy      = data.aws_iam_policy_document.codebuild_policy_document.json
}

resource "aws_iam_role_policy_attachment" "codebuild-attach" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.codebuild_policy.arn
}

resource "aws_codebuild_project" "codebuild" {
  depends_on = [
    aws_ecr_repository.springboot_ecr_repository
  ]
  name         = "${var.prefix}-codebuild"
  service_role = aws_iam_role.codebuild_role.arn
  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                       = "aws/codebuild/standard:3.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    image_pull_credentials_type = "CODEBUILD"
    environment_variable {
      name  = "REPOSITORY_URI"
      value = aws_ecr_repository.springboot_ecr_repository.repository_url
    }
    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = data.aws_region.current.id
    }
    environment_variable {
      name  = "CONTAINER_NAME"
      value = var.ecs_service_name
    }
  }
  source {
    type      = "CODEPIPELINE"
    buildspec = <<BUILDSPEC
version: 0.2
env:
  variables:
    CODEBUILD_SRC_DIR: "/ecs-app"
    SERVICE_NAME: "springbootapp"
runtime-versions:
  java: openjdk8
phases:
  install:
    runtime-versions:
      docker: 18
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - $(aws ecr get-login --region $AWS_DEFAULT_REGION --no-include-email)
      - COMMIT_HASH=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)
      - IMAGE_TAG=$${COMMIT_HASH:=latest}
  build:
    commands:
      - echo Build started on `date`
      - echo Building the jar
      - cd ./ecs-app
      - pwd
      - ls
      - mvn clean install
      - echo get target jar
      - find ./target/ -type f \( -name "*.jar" -not -name "*sources.jar" \) -exec cp {} ./springbootapp.jar \;
      - echo Building the Docker image...
      - pwd
      - ls
      - docker build -t $REPOSITORY_URI:latest .
      - docker tag $REPOSITORY_URI:latest $REPOSITORY_URI:$IMAGE_TAG
  post_build:
    commands:
      - echo Build completed on `date`
      - echo Pushing the Docker image...
      - docker push $REPOSITORY_URI:latest
      - docker push $REPOSITORY_URI:$IMAGE_TAG
      - printf '[{"name":"%s","image":"%s","essential":true,"environment":[{"name":"spring_profile_active","value":"default"}],"portMappings":[{"containerPort":8080}],"logConfiguration":{"logDriver":"awslogs","options":{"awslogs-group":"springbootapp-LogGroup","awslogs-region":"us-east-1","awslogs-stream-prefix":"springbootapp-LogGroup-stream"}}}]' $CONTAINER_NAME $REPOSITORY_URI:$IMAGE_TAG > imagedefinitions.json
artifacts:
    files: imagedefinitions.json
BUILDSPEC
  }
}

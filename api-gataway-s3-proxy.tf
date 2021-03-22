//================= data =
data "aws_partition" "current" {}

data "aws_iam_policy_document" "apigateway_sts_policy" {
  version = "2012-10-17"
  statement {
    principals {
      identifiers = [
        "apigateway.amazonaws.com"]
      type = "Service"
    }
    effect = "Allow"

    actions = [
      "sts:AssumeRole"
    ]
  }
}

locals {
  user_arn_elements = split("/", data.aws_caller_identity.current.arn)
  username          = element(local.user_arn_elements, length(local.user_arn_elements) - 1)
}

//============ API gateway proxy ===========

data "aws_iam_policy_document" "s3_filing_proxy_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject*",
      "s3:PutObject*"]
    resources = [
      "${aws_s3_bucket.filing_content_bucket.arn}*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction"]
    resources = [
      aws_s3_bucket.filing_content_bucket.arn]
  }
}

resource "aws_iam_role" "s3_filing_proxy_role" {
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.apigateway_sts_policy.json
}

resource "aws_iam_role_policy" "s3_filing_proxy_policy" {
  name_prefix = "s3_filing_proxy_policy"
  role        = aws_iam_role.s3_filing_proxy_role.id
  policy      = data.aws_iam_policy_document.s3_filing_proxy_policy_document.json
}


resource "aws_s3_bucket" "filing_content_bucket" {
  bucket = "${var.prefix}-s3-proxy-"
  acl    = "private"
  versioning {
    enabled = false
  }
  cors_rule {
    allowed_headers = [
      "*"]
    allowed_methods = [
      "GET",
      "PUT",
      "POST"]
    allowed_origins = [
      "*"]
    expose_headers = [
      "ETag"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_public_access_block" "private" {
  bucket                  = aws_s3_bucket.filing_content_bucket.id
  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_api_gateway_authorizer" "s3_authorizer" {
  name                             = "${var.prefix}filingAuthorizer"
  type                             = "TOKEN"
  identity_source                  = "method.request.header.Authorization"
  rest_api_id                      = aws_api_gateway_rest_api.s3_filing_proxy_api_gateway.id
  authorizer_result_ttl_in_seconds = 0
  authorizer_uri = join("", [
    "arn:aws:apigateway:",
    data.aws_region.current.name,
    ":lambda:path/2015-03-31/functions/arn:aws:lambda:",
    data.aws_region.current.name,
    ":",
    data.aws_caller_identity.current.account_id,
    ":function:",
    aws_lambda_function.custom_authorizer.function_name,
    "/invocations"
  ])
}

resource "aws_api_gateway_rest_api" "s3_filing_proxy_api_gateway" {
  name = "s3_filing_proxy"
  binary_media_types = [
    "image/jpeg",
    "image/jpg",
    "image/png",
    "image/gif",
    "application/octet-stream",
    "binary/octet-stream",
    "multipart/form-data"
  ]
}

resource "aws_lambda_permission" "s3_filing_proxy_auth_invocation_permissio" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.custom_authorizer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.s3_filing_proxy_api_gateway.execution_arn}/*/*"
}

resource "aws_api_gateway_resource" "s3_filing_proxy_resource_path" {
  parent_id   = aws_api_gateway_rest_api.s3_filing_proxy_api_gateway.root_resource_id
  path_part   = "content"
  rest_api_id = aws_api_gateway_rest_api.s3_filing_proxy_api_gateway.id
}

resource "aws_api_gateway_resource" "s3_filing_proxy_file_resource_path" {
  parent_id   = aws_api_gateway_resource.s3_filing_proxy_resource_path.id
  path_part   = "{file}"
  rest_api_id = aws_api_gateway_rest_api.s3_filing_proxy_api_gateway.id
}

resource "aws_api_gateway_method" "s3_filing_proxy_option_method" {
  authorization = "NONE"
  http_method   = "OPTIONS"
  resource_id   = aws_api_gateway_resource.s3_filing_proxy_file_resource_path.id
  rest_api_id   = aws_api_gateway_rest_api.s3_filing_proxy_api_gateway.id
}

resource "aws_api_gateway_method_response" "s3_filing_proxy_option_response" {
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"      = true
    "method.response.header.Access-Control-Allow-Headers"     = true
    "method.response.header.Access-Control-Allow-Methods"     = true
    "method.response.header.Access-Control-Allow-Credentials" = true
  }
  http_method = aws_api_gateway_method.s3_filing_proxy_option_method.http_method
  resource_id = aws_api_gateway_resource.s3_filing_proxy_file_resource_path.id
  rest_api_id = aws_api_gateway_rest_api.s3_filing_proxy_api_gateway.id

  depends_on = [aws_api_gateway_method.s3_filing_proxy_option_method]
}

resource "aws_api_gateway_integration" "s3_filing_proxy_option_integration" {
  type = "MOCK"
  request_templates = {
    "application/json" = "{statusCode:200}"
  }

  http_method = aws_api_gateway_method.s3_filing_proxy_option_method.http_method
  resource_id = aws_api_gateway_resource.s3_filing_proxy_file_resource_path.id
  rest_api_id = aws_api_gateway_rest_api.s3_filing_proxy_api_gateway.id

  depends_on = [aws_api_gateway_method.s3_filing_proxy_option_method]
}

resource "aws_api_gateway_integration_response" "s3_filing_proxy_option_integration" {
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"      = "'*'"
    "method.response.header.Access-Control-Allow-Headers"     = "'Content-Type,Content-Disposition,Content-Length,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Amz-User-Agent'"
    "method.response.header.Access-Control-Allow-Methods"     = "'OPTIONS,GET,POST'"
    "method.response.header.Access-Control-Allow-Credentials" = "'false'"
  }

  response_templates = {
    "application/json" = ""
  }

  http_method = aws_api_gateway_method.s3_filing_proxy_option_method.http_method
  resource_id = aws_api_gateway_resource.s3_filing_proxy_file_resource_path.id
  rest_api_id = aws_api_gateway_rest_api.s3_filing_proxy_api_gateway.id

  depends_on = [aws_api_gateway_integration.s3_filing_proxy_option_integration]
}


resource "aws_api_gateway_method" "s3_filing_proxy_post_method" {
  authorization    = "CUSTOM"
  authorizer_id    = aws_api_gateway_authorizer.filing_authorizer.id
  api_key_required = false

  request_parameters = {
    "method.request.header.Content-Length" = false
    "method.request.header.Content-Type"   = false
    "method.request.path.file"             = false
  }

  http_method = "POST"
  resource_id = aws_api_gateway_resource.s3_filing_proxy_file_resource_path.id
  rest_api_id = aws_api_gateway_rest_api.s3_filing_proxy_api_gateway.id
}

resource "aws_api_gateway_method_response" "s3_filing_proxy_post_response" {
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"      = true
    "method.response.header.Access-Control-Allow-Credentials" = true
  }

  http_method = aws_api_gateway_method.s3_filing_proxy_post_method.http_method
  resource_id = aws_api_gateway_resource.s3_filing_proxy_file_resource_path.id
  rest_api_id = aws_api_gateway_rest_api.s3_filing_proxy_api_gateway.id

  depends_on = [aws_api_gateway_method.s3_filing_proxy_post_method]
}

resource "aws_api_gateway_integration" "s3_filing_proxy_put_integration" {
  credentials          = aws_iam_role.s3_filing_proxy_role.arn
  passthrough_behavior = "WHEN_NO_MATCH"
  content_handling     = "CONVERT_TO_BINARY"
  type                 = "AWS"

  integration_http_method = "PUT"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:s3:path/${aws_s3_bucket.filing_content_bucket.id}/{file}"

  request_parameters = {
    "integration.request.header.Content-Length" = "method.request.header.Content-Length"
    "integration.request.header.Content-Type"   = "method.request.header.Content-Type"
    "integration.request.path.file"             = "method.request.path.file"
  }

  http_method = aws_api_gateway_method.s3_filing_proxy_post_method.http_method
  resource_id = aws_api_gateway_resource.s3_filing_proxy_file_resource_path.id
  rest_api_id = aws_api_gateway_rest_api.s3_filing_proxy_api_gateway.id

  depends_on = [aws_api_gateway_method.s3_filing_proxy_post_method, aws_s3_bucket.filing_content_bucket]
}

resource "aws_api_gateway_integration_response" "s3_filing_proxy_put_integration" {
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"      = "'*'"
    "method.response.header.Access-Control-Allow-Credentials" = "'false'"
  }
  response_templates = {
    "application/json" = "{}"
  }

  http_method = "POST"
  resource_id = aws_api_gateway_resource.s3_filing_proxy_file_resource_path.id
  rest_api_id = aws_api_gateway_rest_api.s3_filing_proxy_api_gateway.id

  depends_on = [aws_api_gateway_integration.s3_filing_proxy_put_integration]
}

resource "aws_api_gateway_deployment" "filing_api_gateway_deployment" {
  stage_name  = var.prefix
  rest_api_id = aws_api_gateway_rest_api.s3_filing_proxy_api_gateway.id
  description = "Updated at ${timestamp()}"
  depends_on = [
    aws_api_gateway_method.s3_filing_proxy_post_method,
    aws_api_gateway_method.s3_filing_proxy_option_method,

    aws_api_gateway_integration_response.s3_filing_proxy_put_integration,
    aws_api_gateway_integration_response.s3_filing_proxy_option_integration,

    aws_api_gateway_method_response.s3_filing_proxy_post_response,
    aws_api_gateway_method_response.s3_filing_proxy_option_response,

    aws_api_gateway_integration.s3_filing_proxy_put_integration,
    aws_api_gateway_integration.s3_filing_proxy_option_integration
  ]
}

//======= API gateway custom domain

resource "aws_api_gateway_base_path_mapping" "s3_proxy_custom_domain" {
  api_id      = aws_api_gateway_rest_api.s3_filing_proxy_api_gateway.id
  stage_name  = var.prefix
  domain_name = aws_api_gateway_domain_name.s3_proxy_api_gateway_domain.domain_name
  depends_on  = [aws_api_gateway_deployment.filing_api_gateway_deployment]
}

resource "aws_api_gateway_domain_name" "s3_proxy_api_gateway_domain" {
  domain_name     = "s3-proxy.${var.public_subdomain}"
  certificate_arn = module.acm.this_acm_certificate_arn
}

resource "aws_route53_record" "s3_proxy_api_record" {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = aws_api_gateway_domain_name.s3_proxy_api_gateway_domain.domain_name
  type    = "A"

  alias {
    name                   = aws_api_gateway_domain_name.s3_proxy_api_gateway_domain.cloudfront_domain_name
    zone_id                = aws_api_gateway_domain_name.s3_proxy_api_gateway_domain.cloudfront_zone_id
    evaluate_target_health = true
  }
}

//======== logs =========

data "aws_iam_policy_document" "aws_iam_role_cloudwatch_policy" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:FilterLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_api_gateway_account" "demo" {
  cloudwatch_role_arn = aws_iam_role.cloudwatch.arn
}

resource "aws_iam_role" "cloudwatch" {
  name               = "api_gateway_cloudwatch_global"
  assume_role_policy = data.aws_iam_policy_document.apigateway_sts_policy.json
}

resource "aws_iam_role_policy" "cloudwatch" {
  name   = "default"
  role   = aws_iam_role.cloudwatch.id
  policy = data.aws_iam_policy_document.aws_iam_role_cloudwatch_policy.json
}

resource "aws_api_gateway_method_settings" "general_settings" {
  rest_api_id = aws_api_gateway_rest_api.s3_filing_proxy_api_gateway.id
  stage_name  = aws_api_gateway_deployment.filing_api_gateway_deployment.stage_name
  method_path = "*/*"

  settings {
    cache_ttl_in_seconds   = 0
    caching_enabled        = false
    metrics_enabled        = true
    data_trace_enabled     = true
    logging_level          = "INFO"
    throttling_rate_limit  = 100
    throttling_burst_limit = 50
  }
}

resource "aws_api_gateway_account" "demo" {
  cloudwatch_role_arn = aws_iam_role.cloudwatch.arn
}

resource "aws_iam_role" "cloudwatch" {
  name = "api_gateway_cloudwatch_global"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "cloudwatch" {
  name = "default"
  role = aws_iam_role.cloudwatch.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:GetLogEvents",
                "logs:FilterLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}
resource "aws_api_gateway_rest_api" "vg_api_gateway_rest_api" {
  name = var.api_gateway_rest_api
}

resource "aws_api_gateway_api_key" "vg_api_gateway_key" {
  name = var.api_gateway_key 
}
resource "aws_api_gateway_authorizer" "demo" {
  name                   = "demo"
  rest_api_id            = aws_api_gateway_rest_api.vg_api_gateway_rest_api.id
  authorizer_uri         = aws_lambda_function.authorizer.invoke_arn
  authorizer_credentials = aws_iam_role.invocation_role.arn
}

resource "aws_iam_role" "invocation_role" {
  name = "api_gateway_auth_invocation"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "invocation_policy" {
  name = "default"
  role = aws_iam_role.invocation_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "lambda:InvokeFunction",
      "Effect": "Allow",
      "Resource": "${aws_lambda_function.authorizer.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role" "lambda" {
  name = "demo-lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_function" "authorizer" {
  filename      = "lambda-function.zip"
  function_name = "api_gateway_authorizer"
  role          = aws_iam_role.lambda.arn
  handler       = "exports.example"

  source_code_hash = filebase64sha256("lambda-function.zip")
}

resource "aws_api_gateway_domain_name" "example" {
  domain_name = var.domain_name

  certificate_name        = "example-api"
  certificate_body        = file("${path.module}/example.com/example.crt")
  certificate_chain       = file("${path.module}/example.com/ca.crt")
  certificate_private_key = file("${path.module}/example.com/example.key")
}

#resource "aws_api_gateway_base_path_mapping" "test" {
# api_id      = aws_api_gateway_rest_api.vg_api_gateway_rest_api.id
#  stage_name  = aws_api_gateway_deployment.vg_api_gateway_deployment.stage_name
#  domain_name = aws_api_gateway_domain_name.example.domain_name
#}
resource "aws_api_gateway_client_certificate" "demo" {
  description = var.cert_description
}

resource "aws_api_gateway_resource" "vg_api_gateway_resource" {
  count = length(var.path_parts) > 0 ? length(var.path_parts) : 0
  rest_api_id = aws_api_gateway_rest_api.vg_api_gateway_rest_api.id
  parent_id   = aws_api_gateway_rest_api.vg_api_gateway_resource.root_resource_id
  path_part   = element(var.path_parts, count.index)
}

resource "aws_api_gateway_method" "vg_api_gateway_method" {
  count = length(var.path_parts) > 0 ? length(var.path_parts) : 0  
  rest_api_id   = aws_api_gateway_rest_api.vg_api_gateway_rest_api.id
  resource_id   = aws_api_gateway_resource.vg_api_gateway_resource.id
  http_method   = element(var.http_methods, count.index)
  authorization = length(var.authorizations) > 0 ? element(var.authorizations, count.index) : "NONE"
}

resource "aws_api_gateway_integration" "vg_api_gateway_integration" {
  count       = length(aws_api_gateway_method.vg_api_gateway_method.*.id)  
  rest_api_id = aws_api_gateway_rest_api.vg_api_gateway_rest_api.id
  resource_id = aws_api_gateway_resource.vg_api_gateway_resource.id
  http_method = aws_api_gateway_method.vg_api_gateway_method.http_method
  type        = length(var.integration_types) > 0 ? element(var.integration_types, count.index) : "AWS_PROXY"
  cache_key_parameters    = length(var.cache_key_parameters) > 0 ? element(var.cache_key_parameters, count.index) : []
  cache_namespace         = length(var.cache_namespaces) > 0 ? element(var.cache_namespaces, count.index) : ""
}

resource "aws_api_gateway_deployment" "vg_gateway_deployment" {
  depends_on = [aws_api_gateway_integration.vg_api_gateway_integration]
  rest_api_id = aws_api_gateway_rest_api.vg_api_gateway_rest_api.id
  stage_name  = var.stage_name
  variables   = var.variables
  lifecycle {
    create_before_destroy = true
  }
  
}
# Custom Domain set up
resource "aws_api_gateway_domain_name" "vg_api_gateway" {
  count                    = var.custom_domain_enabled ? 1 : 0
  domain_name              = var.domain_name
  regional_certificate_arn = var.regional_aws_acm_certificate_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_route53_record" "vg_api_gateway" {
  count   = var.custom_domain_enabled ? 1 : 0
  zone_id = var.aws_route53_zone_id
  name    = aws_api_gateway_domain_name.vg_api_gateway[0].domain_name
  type    = "A"

  alias {
    name                   = aws_api_gateway_domain_name.vg_api_gateway[0].regional_domain_name
    zone_id                = aws_api_gateway_domain_name.vg_api_gateway[0].regional_zone_id
    evaluate_target_health = true
  }
}

resource "aws_api_gateway_base_path_mapping" "aws_api_gateway_rest_api" {
  count       = var.custom_domain_enabled ? 1 : 0
  api_id      = aws_api_gateway_rest_api.vg_api_gateway_rest_api.id
  domain_name = aws_api_gateway_domain_name.vg_api_gateway[0].domain_name
  stage_name  = aws_api_gateway_deployment.vg_gateway_deployment.stage_name
} 

resource "aws_api_gateway_gateway_response" "test" {
  count         = var.gateway_response_count > 0 ? var.gateway_response_count : 0
  rest_api_id   = aws_api_gateway_rest_api.vg_api_gateway_rest_api.id
  response_type = element(var.response_types, count.index)
  status_code   = length(var.gateway_status_codes) > 0 ? element(var.gateway_status_codes, count.index) : ""

  response_templates = length(var.gateway_response_templates) > 0 ? element(var.gateway_response_templates, count.index) : {}

  response_parameters = length(var.gateway_response_parameters) > 0 ? element(var.gateway_response_parameters, count.index) : {}
}

# API Gateway REST API
resource "aws_api_gateway_rest_api" "secrets_api" {
  name = "${local.name_prefix}-api"
}

# Create resources for the paths
resource "aws_api_gateway_resource" "users" {
  rest_api_id = aws_api_gateway_rest_api.secrets_api.id
  parent_id   = aws_api_gateway_rest_api.secrets_api.root_resource_id
  path_part   = "users"
}

resource "aws_api_gateway_resource" "user_id" {
  rest_api_id = aws_api_gateway_rest_api.secrets_api.id
  parent_id   = aws_api_gateway_resource.users.id
  path_part   = "{userId}"
}

resource "aws_api_gateway_resource" "user_secrets" {
  rest_api_id = aws_api_gateway_rest_api.secrets_api.id
  parent_id   = aws_api_gateway_resource.user_id.id
  path_part   = "secrets"
}

resource "aws_api_gateway_resource" "secrets" {
  rest_api_id = aws_api_gateway_rest_api.secrets_api.id
  parent_id   = aws_api_gateway_rest_api.secrets_api.root_resource_id
  path_part   = "secrets"
}

resource "aws_api_gateway_resource" "secret_id" {
  rest_api_id = aws_api_gateway_rest_api.secrets_api.id
  parent_id   = aws_api_gateway_resource.secrets.id
  path_part   = "{secretId}"
}

resource "aws_api_gateway_resource" "acknowledge" {
  rest_api_id = aws_api_gateway_rest_api.secrets_api.id
  parent_id   = aws_api_gateway_rest_api.secrets_api.root_resource_id
  path_part   = "acknowledge"
}

resource "aws_api_gateway_resource" "ack_secret_id" {
  rest_api_id = aws_api_gateway_rest_api.secrets_api.id
  parent_id   = aws_api_gateway_resource.acknowledge.id
  path_part   = "{secretId}"
}

# Methods and integrations

# GET /users/{userId}/secrets
resource "aws_api_gateway_method" "get_secrets" {
  rest_api_id   = aws_api_gateway_rest_api.secrets_api.id
  resource_id   = aws_api_gateway_resource.user_secrets.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_secrets_integration" {
  rest_api_id             = aws_api_gateway_rest_api.secrets_api.id
  resource_id             = aws_api_gateway_resource.user_secrets.id
  http_method             = aws_api_gateway_method.get_secrets.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.secrets_function.invoke_arn
  passthrough_behavior    = "WHEN_NO_MATCH"
}

# GET /secrets/{secretId}
resource "aws_api_gateway_method" "get_secret_by_id" {
  rest_api_id   = aws_api_gateway_rest_api.secrets_api.id
  resource_id   = aws_api_gateway_resource.secret_id.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_secret_by_id_integration" {
  rest_api_id             = aws_api_gateway_rest_api.secrets_api.id
  resource_id             = aws_api_gateway_resource.secret_id.id
  http_method             = aws_api_gateway_method.get_secret_by_id.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.secrets_function.invoke_arn
  passthrough_behavior    = "WHEN_NO_MATCH"
}

# POST /secrets
resource "aws_api_gateway_method" "create_secret" {
  rest_api_id   = aws_api_gateway_rest_api.secrets_api.id
  resource_id   = aws_api_gateway_resource.secrets.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "create_secret_integration" {
  rest_api_id             = aws_api_gateway_rest_api.secrets_api.id
  resource_id             = aws_api_gateway_resource.secrets.id
  http_method             = aws_api_gateway_method.create_secret.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.secrets_function.invoke_arn
  passthrough_behavior    = "WHEN_NO_MATCH"
}

# GET /acknowledge/{secretId}
resource "aws_api_gateway_method" "acknowledge_secret" {
  rest_api_id   = aws_api_gateway_rest_api.secrets_api.id
  resource_id   = aws_api_gateway_resource.ack_secret_id.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "acknowledge_secret_integration" {
  rest_api_id             = aws_api_gateway_rest_api.secrets_api.id
  resource_id             = aws_api_gateway_resource.ack_secret_id.id
  http_method             = aws_api_gateway_method.acknowledge_secret.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.acknowledge_function.invoke_arn
  passthrough_behavior    = "WHEN_NO_MATCH"
}

# Lambda permissions
resource "aws_lambda_permission" "secrets_apigateway" {
  statement_id  = "AllowInvokeFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.secrets_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.secrets_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "acknowledge_apigateway" {
  statement_id  = "AllowInvokeFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.acknowledge_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.secrets_api.execution_arn}/*/*"
}

# Deployment
resource "aws_api_gateway_deployment" "secrets_api_deployment" {
  depends_on = [
    aws_api_gateway_integration.get_secrets_integration,
    aws_api_gateway_integration.get_secret_by_id_integration,
    aws_api_gateway_integration.create_secret_integration,
    aws_api_gateway_integration.acknowledge_secret_integration,
  ]

  rest_api_id = aws_api_gateway_rest_api.secrets_api.id
}

# Stage
resource "aws_api_gateway_stage" "default" {
  rest_api_id      = aws_api_gateway_rest_api.secrets_api.id
  stage_name       = var.environment
  deployment_id    = aws_api_gateway_deployment.secrets_api_deployment.id
  xray_tracing_enabled = false
}

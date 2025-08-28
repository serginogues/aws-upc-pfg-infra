# API Gateway REST API
resource "aws_api_gateway_rest_api" "secrets_api" {
  name = "${local.name_prefix}-api"
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

resource "aws_api_gateway_resource" "auth" {
  rest_api_id = aws_api_gateway_rest_api.secrets_api.id
  parent_id = aws_api_gateway_rest_api.secrets_api.root_resource_id
  path_part = "auth"
}

resource "aws_api_gateway_resource" "signup" {
  rest_api_id = aws_api_gateway_rest_api.secrets_api.id
  parent_id = aws_api_gateway_resource.auth.id
  path_part = "signup"
}

resource "aws_api_gateway_resource" "signin" {
  rest_api_id = aws_api_gateway_rest_api.secrets_api.id
  parent_id = aws_api_gateway_resource.auth.id
  path_part = "signin"
}

# Methods and integrations
# GET /secrets
resource "aws_api_gateway_method" "get_secrets" {
  rest_api_id   = aws_api_gateway_rest_api.secrets_api.id
  resource_id   = aws_api_gateway_resource.secrets.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_secrets_integration" {
  rest_api_id             = aws_api_gateway_rest_api.secrets_api.id
  resource_id             = aws_api_gateway_resource.secrets.id
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

# POST /auth/signup
resource "aws_api_gateway_method" "signup" {
  rest_api_id   = aws_api_gateway_rest_api.secrets_api.id
  resource_id   = aws_api_gateway_resource.signup.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "auth_signup_integration" {
  rest_api_id = aws_api_gateway_rest_api.secrets_api.id
  resource_id = aws_api_gateway_resource.signup.id
  http_method = aws_api_gateway_method.signup.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.auth_lambda.invoke_arn
  passthrough_behavior = "WHEN_NO_MATCH"
}

# POST /auth/signin
resource "aws_api_gateway_method" "signin" {
  rest_api_id   = aws_api_gateway_rest_api.secrets_api.id
  resource_id   = aws_api_gateway_resource.signin.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "auth_signin_integration" {
  rest_api_id = aws_api_gateway_rest_api.secrets_api.id
  resource_id = aws_api_gateway_resource.signin.id
  http_method = aws_api_gateway_method.signin.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.auth_lambda.invoke_arn
  passthrough_behavior = "WHEN_NO_MATCH"
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

resource "aws_lambda_permission" "auth_apigateway" {
  statement_id = "AllowInvokeFromApiGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth_lambda.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.secrets_api.execution_arn}/*/*"
}

# Deployment
resource "aws_api_gateway_deployment" "secrets_api_deployment" {
  depends_on = [
    aws_api_gateway_integration.get_secrets_integration,
    aws_api_gateway_integration.get_secret_by_id_integration,
    aws_api_gateway_integration.create_secret_integration,
    aws_api_gateway_integration.acknowledge_secret_integration,
    aws_api_gateway_integration.auth_signup_integration,
    aws_api_gateway_integration.auth_signin_integration,
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

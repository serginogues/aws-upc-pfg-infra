# API Gateway
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_api
resource "aws_apigatewayv2_api" "secrets_api" {
  name                       = "${local.name_prefix}-api"
  protocol_type              = "HTTP"
  route_selection_expression = "$request.method $request.path"
  api_key_selection_expression = "$request.header.x-api-key"
  disable_execute_api_endpoint = false
  # ip_address_type defaults to ipv4, puedes especificarlo si quieres:
  ip_address_type            = "ipv4"
}

resource "aws_apigatewayv2_integration" "secrets_integration" {
  api_id                 = aws_apigatewayv2_api.secrets_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.secrets_function.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
  timeout_milliseconds   = 30000
}

resource "aws_apigatewayv2_integration" "acknowledge_integration" {
  api_id                 = aws_apigatewayv2_api.secrets_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.acknowledge_function.invoke_arn
  integration_method     = "GET"
  payload_format_version = "2.0"
  timeout_milliseconds   = 30000
}

resource "aws_lambda_permission" "acknowledge_apigateway" {
  statement_id  = "AllowInvokeFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.acknowledge_function.function_name
  principal     = "apigateway.amazonaws.com"

  # The source ARN is the ARN of the API Gateway
  source_arn = "${aws_apigatewayv2_api.secrets_api.execution_arn}/*"
}

resource "aws_lambda_permission" "secrets_apigateway" {
  statement_id  = "AllowInvokeFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.secrets_function.function_name
  principal     = "apigateway.amazonaws.com"

  # The source ARN is the ARN of the API Gateway
  source_arn = "${aws_apigatewayv2_api.secrets_api.execution_arn}/*"
}

# Get Secrets
resource "aws_apigatewayv2_route" "get_secrets" {
  api_id    = aws_apigatewayv2_api.secrets_api.id
  route_key = "GET /users/{userId}/secrets"  # userId is a path parameter
  target    = "integrations/${aws_apigatewayv2_integration.secrets_integration.id}"
}

# Get Secret by ID
resource "aws_apigatewayv2_route" "get_secret_by_id" {
  api_id    = aws_apigatewayv2_api.secrets_api.id
  route_key = "GET /secrets/{secretId}"  # userId and secretId are path parameters
  target    = "integrations/${aws_apigatewayv2_integration.secrets_integration.id}"
}

# POST Create Secret
resource "aws_apigatewayv2_route" "create_secret" {
  api_id    = aws_apigatewayv2_api.secrets_api.id
  route_key = "POST /secrets"
  target    = "integrations/${aws_apigatewayv2_integration.secrets_integration.id}"
}

# Acknowledge Secret
resource "aws_apigatewayv2_route" "acknowledge_secret" {
  api_id    = aws_apigatewayv2_api.secrets_api.id
  route_key = "GET /acknowledge/{secretId}"  # secretId is a path parameter
  target    = "integrations/${aws_apigatewayv2_integration.acknowledge_integration.id}"
}

#TO BE REMOVED
# resource "aws_api_gateway_rest_api" "secrets_api" {
#   name = "${local.name_prefix}-secrets_api"
# }

# resource "aws_api_gateway_resource" "secrets_api_resource" {
#   parent_id   = ""
#   path_part   = ""
#   rest_api_id = aws_api_gateway_rest_api.secrets_api.id
# }

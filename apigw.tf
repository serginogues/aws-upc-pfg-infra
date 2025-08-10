# API Gateway
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_api
# resource "aws_apigatewayv2_api" "demo_http" {
#   name                       = "${local.name_prefix}-api"
#   protocol_type              = "HTTP"
#   route_selection_expression = "$request.method $request.path"
#   api_key_selection_expression = "$request.header.x-api-key"
#   disable_execute_api_endpoint = false
#   # ip_address_type defaults to ipv4, puedes especificarlo si quieres:
#   ip_address_type            = "ipv4"
#
# }
#
# resource "aws_apigatewayv2_integration" "messageGet_integration" {
#   api_id                 = aws_apigatewayv2_api.demo_http.id
#   integration_type       = "AWS_PROXY"
#   integration_uri        = aws_lambda_function.messageGet.arn
#   integration_method     = "POST"
#   payload_format_version = "2.0"
#   timeout_milliseconds   = 30000
# }
#
# resource "aws_apigatewayv2_route" "messageGet_route" {
#   api_id    = aws_apigatewayv2_api.demo_http.id
#   route_key = "POST /messageGet"  # Cambia según tu ruta HTTP real
#   target    = "integrations/${aws_apigatewayv2_integration.messageGet_integration.id}"
# }
#
# resource "aws_lambda_permission" "apigw_lambda_messageGet" {
#   statement_id  = "AllowAPIGatewayInvokeMessageGet"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.messageGet.function_name
#   principal     = "apigateway.amazonaws.com"
#   source_arn    = "${aws_apigatewayv2_api.demo_http.execution_arn}/*/*"
# }

#TODO
resource "aws_api_gateway_rest_api" "secrets_api" {
  name = "${local.name_prefix}-secrets_api"
}

resource "aws_api_gateway_resource" "secrets_api_resource" {
  parent_id   = ""
  path_part   = ""
  rest_api_id = aws_api_gateway_rest_api.secrets_api.id
}

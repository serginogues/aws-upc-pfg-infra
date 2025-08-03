# API Gateway
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_api

#TODO
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
# # Lambda GET message
# resource "aws_lambda_function" "messageGet" {
#   function_name = "${local.name_prefix}-messageGet"
#   runtime       = "nodejs22.x"
#   role          = aws_iam_role.lambda_exec.arn
#   handler       = "index.handler"
#   memory_size   = 128
#   timeout       = 3
#   architectures = ["x86_64"]
#   ephemeral_storage {
#     size = 512
#   }
#
#   # filename         = "path/to/messageGet.zip"  # Cambia a tu zip local o S3
#   # source_code_hash = filebase64sha256("path/to/messageGet.zip")
#
#   description = ""
#   publish     = true
# }
# #TODO: deploy lambda js zip + provide s3 output
#
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

# Lambda-QR
# lambda_s3_bucket_id = "aws-upc-pfg-code-lambda-bucket"
# python_print_s3_key = "aws-upc-pfg-code-python_print.zip"
data "terraform_remote_state" "aws_upc_pfg_tfstate" {
  backend = "s3"
  config = {
    bucket = "aws-upc-pfg-tfstate-bucket"  # Producer project's state bucket
    key    = "aws-upc-pfg-code/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_lambda_function" "lambda_automatic_zip_deploy_test" {
  function_name = "${local.name_prefix}-python_print_function"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  runtime       = "python3.9"

  # Reference the S3 object data source
  # Optional: Use the object version if you want versioning
  s3_bucket     = data.terraform_remote_state.aws_upc_pfg_tfstate.outputs.lambda_s3_bucket
  s3_key        = data.terraform_remote_state.aws_upc_pfg_tfstate.outputs.python_print_s3_key

  # Other optional parameters
  memory_size = 128
  timeout     = 3
}


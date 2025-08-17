# Lambda Secrets
resource "aws_lambda_function" "secrets_function" {
  role          = aws_iam_role.lambda_exec.arn
  function_name = "${local.name_prefix}-secrets_function"
  handler       = "index.handler"
  runtime       = "nodejs22.x"
  memory_size   = 512
  timeout       = 30
  architectures = ["x86_64"]

  s3_bucket     = data.terraform_remote_state.aws_upc_pfg_tfstate.outputs.lambda_s3_bucket
  s3_key        = data.terraform_remote_state.aws_upc_pfg_tfstate.outputs.secrets_function_s3_key
  s3_object_version   = data.terraform_remote_state.aws_upc_pfg_tfstate.outputs.secrets_function_s3_object_version

  environment {
    variables = {
      DYNAMO_DB_TABLE       = aws_dynamodb_table.secrets.name
      SQS_JOURNAL_QUEUE_URL = aws_sqs_queue.secrets_journal.url
      SQS_QR_CODE_QUEUE_URL = aws_sqs_queue.qr_code_queue.url
    }
  }
}

# Acknowledge Lambda
resource "aws_lambda_function" "acknowledge_function" {
  role          = aws_iam_role.lambda_exec.arn
  function_name = "${local.name_prefix}-acknowledge_function"
  handler       = "index.handler"
  runtime       = "nodejs22.x"
  memory_size   = 512
  timeout       = 30
  architectures = ["x86_64"]

  s3_bucket     = data.terraform_remote_state.aws_upc_pfg_tfstate.outputs.lambda_s3_bucket
  s3_key        = data.terraform_remote_state.aws_upc_pfg_tfstate.outputs.acknowledge_function_s3_key
  s3_object_version   = data.terraform_remote_state.aws_upc_pfg_tfstate.outputs.acknowledge_function_s3_object_version

  environment {
    variables = {
      DYNAMO_DB_TABLE       = aws_dynamodb_table.secrets.name
      SQS_JOURNAL_QUEUE_URL = aws_sqs_queue.secrets_journal.url
      SQS_QR_CODE_QUEUE_URL = aws_sqs_queue.qr_code_queue.url
    }
  }
}

# QR Lambda
resource "aws_lambda_function" "qrcode_generator_function" {
  role          = aws_iam_role.lambda_exec.arn
  function_name = "${local.name_prefix}-qr_code_generator_function"
  handler       = "index.handler"
  runtime       = "nodejs22.x"
  memory_size   = 512
  timeout       = 30
  architectures = ["x86_64"]

  s3_bucket     = data.terraform_remote_state.aws_upc_pfg_tfstate.outputs.lambda_s3_bucket
  s3_key        = data.terraform_remote_state.aws_upc_pfg_tfstate.outputs.qrcode_generator_function_s3_key
  s3_object_version   = data.terraform_remote_state.aws_upc_pfg_tfstate.outputs.qrcode_generator_function_s3_object_version

  environment {
    variables = {
      DYNAMO_DB_TABLE       = aws_dynamodb_table.secrets.name
      SQS_JOURNAL_QUEUE_URL = aws_sqs_queue.secrets_journal.url
      SQS_QR_CODE_QUEUE_URL = aws_sqs_queue.qr_code_queue.url
      QR_CODES_BUCKET_NAME  = aws_s3_bucket.qrcodes-bucket.bucket
    }
  }
}

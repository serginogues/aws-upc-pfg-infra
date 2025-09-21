# Secrets Lambda
resource "aws_lambda_function" "secrets_function" {
  role          = aws_iam_role.lambda_exec.arn
  function_name = "${local.name_prefix}-secrets_function"
  handler       = "index.handler"
  runtime       = "nodejs22.x"
  memory_size   = 512
  timeout       = 30
  architectures = ["x86_64"]

  s3_bucket         = data.terraform_remote_state.aws_upc_pfg_tfstate.outputs.lambda_s3_bucket
  s3_key            = data.terraform_remote_state.aws_upc_pfg_tfstate.outputs.secrets_function_s3_key
  s3_object_version = data.terraform_remote_state.aws_upc_pfg_tfstate.outputs.secrets_function_s3_object_version

  environment {
    variables = {
      DYNAMO_DB_TABLE       = aws_dynamodb_table.secrets.name
      SQS_JOURNAL_QUEUE_URL = aws_sqs_queue.secrets_journal.url
      SQS_QR_CODE_QUEUE_URL = aws_sqs_queue.qr_code_queue.url
      COGNITO_USER_POOL_ID  = aws_cognito_user_pool.secrets_user_pool.id
      COGNITO_CLIENT_ID     = aws_cognito_user_pool_client.secrets_cognito_client.id
      COGNITO_CLIENT_SECRET = aws_cognito_user_pool_client.secrets_cognito_client.client_secret
      # AWS_REGION            = var.region
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

  s3_bucket         = data.terraform_remote_state.aws_upc_pfg_tfstate.outputs.lambda_s3_bucket
  s3_key            = data.terraform_remote_state.aws_upc_pfg_tfstate.outputs.acknowledge_function_s3_key
  s3_object_version = data.terraform_remote_state.aws_upc_pfg_tfstate.outputs.acknowledge_function_s3_object_version

  environment {
    variables = {
      DYNAMO_DB_TABLE       = aws_dynamodb_table.secrets.name
      SQS_JOURNAL_QUEUE_URL = aws_sqs_queue.secrets_journal.url
      SQS_QR_CODE_QUEUE_URL = aws_sqs_queue.qr_code_queue.url
      COGNITO_USER_POOL_ID  = aws_cognito_user_pool.secrets_user_pool.id
      COGNITO_CLIENT_ID     = aws_cognito_user_pool_client.secrets_cognito_client.id
      COGNITO_CLIENT_SECRET = aws_cognito_user_pool_client.secrets_cognito_client.client_secret
      # AWS_REGION            = var.region
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

  s3_bucket         = data.terraform_remote_state.aws_upc_pfg_tfstate.outputs.lambda_s3_bucket
  s3_key            = data.terraform_remote_state.aws_upc_pfg_tfstate.outputs.qrcode_generator_function_s3_key
  s3_object_version = data.terraform_remote_state.aws_upc_pfg_tfstate.outputs.qrcode_generator_function_s3_object_version

  environment {
    variables = {
      DYNAMO_DB_TABLE       = aws_dynamodb_table.secrets.name
      SQS_JOURNAL_QUEUE_URL = aws_sqs_queue.secrets_journal.url
      SQS_QR_CODE_QUEUE_URL = aws_sqs_queue.qr_code_queue.url
      QR_CODES_BUCKET_NAME  = aws_s3_bucket.qrcodes-bucket.bucket
      COGNITO_USER_POOL_ID  = aws_cognito_user_pool.secrets_user_pool.id
      COGNITO_CLIENT_ID     = aws_cognito_user_pool_client.secrets_cognito_client.id
      COGNITO_CLIENT_SECRET = aws_cognito_user_pool_client.secrets_cognito_client.client_secret
      # AWS_REGION            = var.region
    }
  }
}

# Auth Lambda
resource "aws_lambda_function" "auth_lambda" {
  role          = aws_iam_role.lambda_exec.arn
  function_name = "${local.name_prefix}-auth_lambda"
  handler       = "index.handler"
  runtime       = "nodejs22.x"
  memory_size   = 512
  timeout       = 30
  architectures = ["x86_64"]

  s3_bucket         = data.terraform_remote_state.aws_upc_pfg_tfstate.outputs.lambda_s3_bucket
  s3_key            = data.terraform_remote_state.aws_upc_pfg_tfstate.outputs.auth_function_s3_key
  s3_object_version = data.terraform_remote_state.aws_upc_pfg_tfstate.outputs.auth_function_s3_object_version

  environment {
    variables = {
      COGNITO_USER_POOL_ID  = aws_cognito_user_pool.secrets_user_pool.id
      COGNITO_CLIENT_ID     = aws_cognito_user_pool_client.secrets_cognito_client.id
      COGNITO_CLIENT_SECRET = aws_cognito_user_pool_client.secrets_cognito_client.client_secret
      # AWS_REGION            = var.region
    }
  }
}

# Send QR with SNS topic
resource "aws_lambda_function" "send_qrcode_email_notification_function" {
  role          = aws_iam_role.lambda_exec.arn
  function_name = "${local.name_prefix}-send_qrcode_email_notification_function"
  handler       = "index.handler"
  runtime       = "nodejs22.x"
  memory_size   = 512
  timeout       = 30
  architectures = ["x86_64"]
  s3_bucket         = data.terraform_remote_state.aws_upc_pfg_tfstate.outputs.lambda_s3_bucket
  s3_key            = data.terraform_remote_state.aws_upc_pfg_tfstate.outputs.send_qrcode_email_notification_function_s3_key
  s3_object_version = data.terraform_remote_state.aws_upc_pfg_tfstate.outputs.send_qrcode_email_notification_function_s3_object_version

  environment {
    variables = {
      USER_POOL_ID         = aws_cognito_user_pool.secrets_user_pool.id
      SENDER_EMAIL         = var.sender_email
      QR_CODES_BUCKET_NAME = aws_s3_bucket.qrcodes-bucket.bucket
      COGNITO_USER_POOL_ID  = aws_cognito_user_pool.secrets_user_pool.id
      # AWS_REGION           = var.region
    }
  }
}

# SQS Queues
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue

# Publisher: API Gateway, Subscriber: Lambda-Post
resource "aws_sqs_queue" "secrets_journal" {
  name = "${local.name_prefix}-secrets-journal-queue"
}

# Publisher: Lambda-Post, Subscriber: Lambda-QR
resource "aws_sqs_queue" "qr_code_queue" {
  name = "${local.name_prefix}-qr-code-queue"
}

resource "aws_lambda_event_source_mapping" "qr_code_queue_mapping" {
  event_source_arn = aws_sqs_queue.qr_code_queue.arn
  function_name    = aws_lambda_function.qrcode_generator_function.function_name
  batch_size       = 1
  enabled          = true
}
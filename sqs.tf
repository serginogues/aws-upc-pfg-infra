# SQS Queues
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue

# Publisher: API Gateway, Subscriber: Lambda-Post
resource "aws_sqs_queue" "secrets_journal" {
  name = "${local.name_prefix}-secrets-journal-queue"
}

# Publisher: Lambda-Post, Subscriber: Lambda-QR
resource "aws_sqs_queue" "qr_queue" {
  name = "${local.name_prefix}-qr-queue"
}
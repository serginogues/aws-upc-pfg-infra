# DynamoDB Table
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table
resource "aws_dynamodb_table" "secrets" {
  name = "${local.name_prefix}-secrets"
  billing_mode = "PAY_PER_REQUEST" # better cost policy when creating new tables
  hash_key  = "pk"
  range_key = "sk"

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }
  /*
  A DynamoDB Global Secondary Index (GSI) is an index that allows you to query a DynamoDB table
  using different attributes than the table's primary key.
  It provides a way to access data based on different criteria without needing to perform a full
  table scan, improving query performance and flexibility.
  See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table#global_secondary_index
   */
  global_secondary_index {
    name            = "sk-index"
    hash_key        = "sk"
    projection_type = "ALL"
    read_capacity   = 1
    write_capacity  = 1
  }

  tags = {
    Name = "secrets"
  }
}
#TODO:
# Option1: TTL within DynamoDB
# Option2: Success-SQS with TTL,
#         when TTL is triggered items are stored to Delete-SQS.
#         Then Lambda-Delete is subscribed to Delete-SQS and
#         replaces Secret from DynamoDB.

# S3 bucket for QRs
resource "aws_s3_bucket" "qr_codes" {
  bucket = "${local.name_prefix}-qr-codes"
}

# Future improvements:
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning
# resource "aws_s3_bucket_versioning" "qr_codes" {
#   bucket = aws_s3_bucket.qr_codes.id
#   versioning_configuration {
#     status = "Enabled"
#   }
# }
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
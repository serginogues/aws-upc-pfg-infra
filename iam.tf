# IAM Roles for Cognito
resource "aws_iam_role" "auth_role" {
  name = "cognito_authenticated"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = {
        Federated = "cognito-identity.amazonaws.com"
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.identities.id
        },
        "ForAnyValue:StringLike" = {
          "cognito-identity.amazonaws.com:amr" = "authenticated"
        }
      }
    }]
  })
}

resource "aws_iam_role" "unauth_role" {
  name = "cognito_unauthenticated"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = {
        Federated = "cognito-identity.amazonaws.com"
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.identities.id
        },
        "ForAnyValue:StringLike" = {
          "cognito-identity.amazonaws.com:amr" = "unauthenticated"
        }
      }
    }]
  })
}

resource "aws_cognito_identity_pool_roles_attachment" "attach" {
  identity_pool_id = aws_cognito_identity_pool.identities.id
  roles = {
    authenticated   = aws_iam_role.auth_role.arn
    unauthenticated = aws_iam_role.unauth_role.arn
  }
}

# IAM Policies for Cognito
resource "aws_iam_role_policy" "auth_policy" {
  role = aws_iam_role.auth_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:UpdateItem",
        # "dynamodb:DeleteItem",
        "dynamodb:Query",
        # "dynamodb:Scan"
      ]
      Resource = aws_dynamodb_table.secrets.arn
    }]
  })
}

resource "aws_iam_role_policy" "unauth_policy" {
  role = aws_iam_role.unauth_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:UpdateItem",
        # "dynamodb:DeleteItem",
        "dynamodb:Query",
        # "dynamodb:Scan"
      ]
      Resource = aws_dynamodb_table.secrets.arn
    }]
  })
}

resource "aws_iam_role_policy" "lambda_cognito_policy" {
  role = aws_iam_role.lambda_exec.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = [
        "cognito-idp:SignUp",
        "cognito-idp:AdminInitiateAuth",
        "cognito-idp:AdminGetUser",
        "cognito-idp:AdminConfirmSignUp"
      ],
      Resource = "*"
    }]
  })
}

# IAM Role for Lambdas
# See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role#basic-example
resource "aws_iam_role" "lambda_exec" {
  name = "${local.name_prefix}-lambda-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for Lambda basic execution
resource "aws_iam_policy" "lambda_basic_execution" {
  name        = "${local.name_prefix}-lambda-basic-exec"
  description = "Policy for Lambda basic execution"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# Policy for Lambda-Post
resource "aws_iam_policy" "lambda_post_policy" {
  name        = "${local.name_prefix}-lambda-post-policy"
  description = "Policy for Lambda-Post"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ]
        Resource = [
          aws_sqs_queue.secrets_journal.arn,
          aws_sqs_queue.qr_code_queue.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]

        Resource = "*"
      }
    ]
  })
}

# Add DynamoDB Policy for Lambda functions
resource "aws_iam_policy" "lambda_dynamodb_policy" {
  name        = "${local.name_prefix}-lambda-dynamodb-policy"
  description = "Policy for Lambda DynamoDB access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          # "dynamodb:DeleteItem",
          "dynamodb:Query",
          # "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.secrets.arn,
          "${aws_dynamodb_table.secrets.arn}/index/*" # For GSI access
        ]
      }
    ]
  })
}

# S3 Policy for QR codes bucket access
resource "aws_iam_policy" "lambda_s3_policy" {
  name        = "${local.name_prefix}-lambda-s3-policy"
  description = "Policy for Lambda S3 access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.qrcodes-bucket.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.qrcodes-bucket.arn
      }
    ]
  })
}

# Attach policies to lambda_exec role
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_basic_execution.arn
}

resource "aws_iam_role_policy_attachment" "lambda_post_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_post_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_dynamodb_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_s3_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_s3_policy.arn
}

#TODO: Similar policies must be created for other Lambdas

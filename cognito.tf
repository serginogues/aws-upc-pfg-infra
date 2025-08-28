resource "aws_cognito_user_pool" "secrets_user_pool" {
  name                     = "secrets-user-pool"
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = false
  }

  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true
    string_attribute_constraints {
      min_length = 7
      max_length = 256
    }
  }
}

resource "aws_cognito_user_pool_client" "secrets_cognito_client" {
  name                = "secrets-client"
  user_pool_id        = aws_cognito_user_pool.secrets_user_pool.id
  generate_secret     = true # Required for backend-only auth
  explicit_auth_flows = ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
}

resource "aws_cognito_identity_pool" "identities" {
  identity_pool_name               = "secrets-user-pool"
  allow_unauthenticated_identities = true

  cognito_identity_providers {
    provider_name           = "cognito-idp.${var.region}.amazonaws.com/${aws_cognito_user_pool.secrets_user_pool.id}"
    client_id               = aws_cognito_user_pool_client.secrets_cognito_client.id
    server_side_token_check = false
  }
}

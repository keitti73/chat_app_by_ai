# =================================================================
# Amazon Cognito Authentication Configuration
# =================================================================
# ユーザー認証・管理システムの設定
# セキュリティのベストプラクティスを実装

# =================================================================
# Cognito User Pool
# =================================================================

resource "aws_cognito_user_pool" "chat_user_pool" {
  name = "${local.name_prefix}-user-pool"

  # Username configuration
  alias_attributes = ["email"]
  username_configuration {
    case_sensitive = false
  }

  # Password policy
  password_policy {
    minimum_length                   = var.cognito_password_minimum_length
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = false
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  # Account recovery
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # Email configuration
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
    # 本番環境では SES を使用することを推奨
    # email_sending_account = "DEVELOPER"
    # source_arn            = aws_ses_identity.cognito_email.arn
  }

  # Auto-verified attributes
  auto_verified_attributes = var.cognito_auto_verified_attributes

  # User attributes schema
  schema {
    attribute_data_type = "String"
    name                = "email"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  schema {
    attribute_data_type = "String"
    name                = "preferred_username"
    required            = false
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 128
    }
  }

  # Device configuration
  device_configuration {
    challenge_required_on_new_device      = false
    device_only_remembered_on_user_prompt = true
  }

  # MFA configuration
  mfa_configuration = var.environment == "prod" ? "OPTIONAL" : "OFF"

  dynamic "software_token_mfa_configuration" {
    for_each = var.environment == "prod" ? [1] : []
    content {
      enabled = true
    }
  }

  # Lambda triggers for customization
  # lambda_config {
  #   pre_sign_up                    = aws_lambda_function.cognito_pre_signup[0].arn
  #   post_authentication           = aws_lambda_function.cognito_post_auth[0].arn
  #   post_confirmation             = aws_lambda_function.cognito_post_confirm[0].arn
  # }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-user-pool"
    Type = "Cognito-UserPool"
  })
}

# =================================================================
# Cognito User Pool Client
# =================================================================

resource "aws_cognito_user_pool_client" "chat_client" {
  name         = "${local.name_prefix}-client"
  user_pool_id = aws_cognito_user_pool.chat_user_pool.id

  # Client configuration
  generate_secret = false

  # Token validity
  access_token_validity  = 1  # 1 hour
  id_token_validity      = 1  # 1 hour  
  refresh_token_validity = 30 # 30 days

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  # OAuth configuration
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]

  # Callback URLs (for web and mobile apps)
  callback_urls = [
    "http://localhost:3000",
    "https://localhost:3000",
    # 本番環境のURLを追加
    # "https://your-domain.com"
  ]

  logout_urls = [
    "http://localhost:3000",
    "https://localhost:3000",
    # 本番環境のURLを追加
    # "https://your-domain.com"
  ]

  # Supported identity providers
  supported_identity_providers = ["COGNITO"]

  # Attribute permissions
  read_attributes = [
    "email",
    "email_verified",
    "preferred_username"
  ]

  write_attributes = [
    "email",
    "preferred_username"
  ]

  # Prevent user existence errors
  prevent_user_existence_errors = "ENABLED"

  # Explicit authentication flows
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
}

# =================================================================
# Cognito User Pool Domain
# =================================================================

resource "aws_cognito_user_pool_domain" "chat_domain" {
  domain       = "${local.name_prefix}-auth-${random_string.domain_suffix.result}"
  user_pool_id = aws_cognito_user_pool.chat_user_pool.id
}

resource "random_string" "domain_suffix" {
  length  = 8
  special = false
  upper   = false
}

# =================================================================
# Cognito Identity Pool
# =================================================================

resource "aws_cognito_identity_pool" "chat_identity_pool" {
  identity_pool_name               = "${local.name_prefix}-identity-pool"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.chat_client.id
    provider_name           = aws_cognito_user_pool.chat_user_pool.endpoint
    server_side_token_check = true
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-identity-pool"
    Type = "Cognito-IdentityPool"
  })
}

# =================================================================
# IAM Roles for Cognito Identity Pool
# =================================================================

# Authenticated users role
resource "aws_iam_role" "cognito_authenticated" {
  name = "${local.name_prefix}-cognito-authenticated-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.chat_identity_pool.id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "authenticated"
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-cognito-authenticated-role"
    Type = "IAM-Role"
  })
}

# Policy for authenticated users
resource "aws_iam_role_policy" "cognito_authenticated_policy" {
  name = "${local.name_prefix}-cognito-authenticated-policy"
  role = aws_iam_role.cognito_authenticated.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "appsync:GraphQL"
        ]
        Resource = "${aws_appsync_graphql_api.chat_api.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "cognito-sync:*",
          "cognito-identity:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# =================================================================
# Identity Pool Role Attachment
# =================================================================

resource "aws_cognito_identity_pool_roles_attachment" "chat_identity_pool_roles" {
  identity_pool_id = aws_cognito_identity_pool.chat_identity_pool.id

  roles = {
    "authenticated" = aws_iam_role.cognito_authenticated.arn
  }
}

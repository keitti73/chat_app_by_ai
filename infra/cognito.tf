# =================================================================
# Amazon Cognito 認証リソース設定
# =================================================================
# Cognitoとは、AWSが提供するユーザー認証・管理サービスです
# ユーザー登録、ログイン、パスワード管理などを簡単に実装できます

# Cognito User Pool（ユーザープール）
# ユーザーの情報（メールアドレス、パスワードなど）を管理するデータベースのようなもの
resource "aws_cognito_user_pool" "chat_user_pool" {
  name = "${var.project_name}-user-pool"

  # ユーザー名の設定（メールアドレスでログインできるようにする）
  alias_attributes = ["email"]
  
  # ユーザー名の大文字小文字を区別しない
  username_configuration {
    case_sensitive = false
  }

  # パスワードポリシー（パスワードの強度設定）
  password_policy {
    minimum_length    = 8           # 最小8文字
    require_lowercase = true        # 小文字必須
    require_numbers   = true        # 数字必須
    require_symbols   = false       # 記号は任意
    require_uppercase = true        # 大文字必須
  }

  # アカウント復旧設定
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"   # メールでパスワードリセット
      priority = 1
    }
  }

  # メール設定
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"  # Cognitoのデフォルトメール機能を使用
  }

  # 自動確認設定（メールアドレスを自動確認）
  auto_verified_attributes = ["email"]

  # ユーザー属性の設定
  schema {
    attribute_data_type = "String"
    name               = "email"
    required           = true       # メールアドレスは必須
    mutable            = true       # 変更可能
  }

  schema {
    attribute_data_type = "String"
    name               = "name"
    required           = true       # 名前は必須
    mutable            = true       # 変更可能
  }

  tags = {
    Name = "${var.project_name}-user-pool"
  }
}

# Cognito User Pool Client（アプリクライアント）
# フロントエンドアプリがCognitoと通信するための設定
resource "aws_cognito_user_pool_client" "chat_client" {
  name         = "${var.project_name}-client"
  user_pool_id = aws_cognito_user_pool.chat_user_pool.id

  # 認証フロー設定
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",          # SRP認証（安全なパスワード認証）
    "ALLOW_REFRESH_TOKEN_AUTH",     # リフレッシュトークン認証
    "ALLOW_USER_PASSWORD_AUTH"      # ユーザー名・パスワード認証
  ]

  # トークンの有効期限設定
  access_token_validity  = 60    # アクセストークン60分
  id_token_validity     = 60    # IDトークン60分
  refresh_token_validity = 30   # リフレッシュトークン30日

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  # セキュリティ設定
  generate_secret                = false    # クライアントシークレットは使わない（SPAアプリのため）
  prevent_user_existence_errors  = "ENABLED"  # ユーザー存在確認エラーを防ぐ
  enable_token_revocation        = true     # トークン無効化を有効

  # OAuth設定（将来のソーシャルログイン対応用）
  supported_identity_providers = ["COGNITO"]
  
  # 読み書き可能な属性設定
  read_attributes  = ["email", "name"]
  write_attributes = ["email", "name"]
}

# Cognito Identity Pool（アイデンティティプール）
# 認証されたユーザーに一時的なAWS認証情報を提供
resource "aws_cognito_identity_pool" "chat_identity_pool" {
  identity_pool_name               = "${var.project_name}-identity-pool"
  allow_unauthenticated_identities = false  # 未認証ユーザーは許可しない

  # Cognitoユーザープールと連携
  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.chat_client.id
    provider_name          = aws_cognito_user_pool.chat_user_pool.endpoint
    server_side_token_check = false
  }

  tags = {
    Name = "${var.project_name}-identity-pool"
  }
}

# 認証されたユーザー用のIAMロール
resource "aws_iam_role" "authenticated_role" {
  name = "${var.project_name}-cognito-authenticated-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
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
}

# 認証されたユーザーのアクセス権限ポリシー
resource "aws_iam_role_policy" "authenticated_policy" {
  name = "${var.project_name}-cognito-authenticated-policy"
  role = aws_iam_role.authenticated_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "appsync:GraphQL"  # AppSync GraphQL APIへのアクセス許可
        ]
        Resource = "${aws_appsync_graphql_api.chat_api.arn}/*"
      }
    ]
  })
}

# Identity Poolとロールの関連付け
resource "aws_cognito_identity_pool_roles_attachment" "identity_pool_roles" {
  identity_pool_id = aws_cognito_identity_pool.chat_identity_pool.id

  roles = {
    "authenticated" = aws_iam_role.authenticated_role.arn
  }
}

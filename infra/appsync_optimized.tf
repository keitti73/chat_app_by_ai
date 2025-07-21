# =================================================================
# AppSync GraphQL API Configuration
# =================================================================
# AWS AppSyncのメイン設定ファイル
# GraphQL APIの設定、認証、ログ設定を管理

# =================================================================
# CloudWatch Log Group for AppSync
# =================================================================

resource "aws_cloudwatch_log_group" "appsync_logs" {
  name              = "/aws/appsync/apis/${local.name_prefix}-api"
  retention_in_days = var.environment == "prod" ? 30 : 7

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-appsync-logs"
    Type = "CloudWatch-LogGroup"
  })
}

# =================================================================
# AppSync GraphQL API
# =================================================================

resource "aws_appsync_graphql_api" "chat_api" {
  authentication_type = "AMAZON_COGNITO_USER_POOLS"
  name                = "${local.name_prefix}-api"
  schema              = file("${path.module}/../schema.graphql")

  # Cognito認証設定
  user_pool_config {
    aws_region     = var.aws_region
    default_action = "ALLOW"
    user_pool_id   = aws_cognito_user_pool.chat_user_pool.id
  }

  # 追加認証プロバイダー（開発環境のみAPI Key使用）
  dynamic "additional_authentication_provider" {
    for_each = var.environment != "prod" ? [1] : []
    content {
      authentication_type = "API_KEY"
    }
  }

  # ログ設定
  log_config {
    cloudwatch_logs_role_arn = aws_iam_role.appsync_logs.arn
    field_log_level          = var.appsync_log_level
    exclude_verbose_content  = var.environment == "prod" ? true : false
  }

  # X-Ray トレーシング
  dynamic "xray_config" {
    for_each = var.enable_xray_tracing ? [1] : []
    content {
      enabled = true
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-graphql-api"
    Type = "AppSync-API"
  })
}

# =================================================================
# AppSync API Key (開発用)
# =================================================================

resource "aws_appsync_api_key" "chat_api_key" {
  api_id      = aws_appsync_graphql_api.chat_api.id
  description = "API Key for ${local.name_prefix}"
  expires     = timeadd(timestamp(), "${var.appsync_api_key_expires_days}d")

  # 本番環境ではAPI Keyを無効化することを推奨
  count = var.environment != "prod" ? 1 : 0
}

# =================================================================
# AppSync Domain Name (Optional - for custom domains)
# =================================================================

# カスタムドメインを使用する場合の設定
# resource "aws_appsync_domain_name" "chat_api_domain" {
#   count           = var.custom_domain_name != "" ? 1 : 0
#   domain_name     = var.custom_domain_name
#   certificate_arn = var.certificate_arn
# }

# resource "aws_appsync_domain_name_api_association" "chat_api_domain_association" {
#   count       = var.custom_domain_name != "" ? 1 : 0
#   api_id      = aws_appsync_graphql_api.chat_api.id
#   domain_name = aws_appsync_domain_name.chat_api_domain[0].domain_name
# }

# =================================================================
# AppSync Enhanced Metrics (CloudWatch メトリクス)
# =================================================================

resource "aws_cloudwatch_dashboard" "appsync_dashboard" {
  count          = var.enable_cloudwatch_insights ? 1 : 0
  dashboard_name = "${local.name_prefix}-appsync-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/AppSync", "4XXError", "GraphQLAPIId", aws_appsync_graphql_api.chat_api.id],
            [".", "5XXError", ".", "."],
            [".", "Latency", ".", "."],
            [".", "Requests", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "AppSync API Metrics"
          period  = 300
        }
      }
    ]
  })
}

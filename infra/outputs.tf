# =================================================================
# Terraform Outputs Configuration
# =================================================================
# 他のシステムやデプロイプロセスで使用される重要な値を出力

# =================================================================
# AppSync API Information
# =================================================================

output "appsync_graphql_endpoint" {
  description = "AppSync GraphQL endpoint URL"
  value       = aws_appsync_graphql_api.chat_api.uris["GRAPHQL"]
}

output "appsync_api_id" {
  description = "AppSync API ID"
  value       = aws_appsync_graphql_api.chat_api.id
}

output "appsync_api_key" {
  description = "AppSync API Key (for development only)"
  value       = var.environment != "prod" ? aws_appsync_api_key.chat_api_key[0].key : "Not available in production"
  sensitive   = true
}

output "appsync_api_arn" {
  description = "AppSync API ARN"
  value       = aws_appsync_graphql_api.chat_api.arn
}

# =================================================================
# Cognito Information
# =================================================================

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.chat_user_pool.id
}

output "cognito_user_pool_arn" {
  description = "Cognito User Pool ARN"
  value       = aws_cognito_user_pool.chat_user_pool.arn
}

output "cognito_user_pool_client_id" {
  description = "Cognito User Pool Client ID"
  value       = aws_cognito_user_pool_client.chat_client.id
}

output "cognito_identity_pool_id" {
  description = "Cognito Identity Pool ID"
  value       = aws_cognito_identity_pool.chat_identity_pool.id
}

output "cognito_user_pool_domain" {
  description = "Cognito User Pool Domain"
  value       = aws_cognito_user_pool_domain.chat_domain.domain
}

output "cognito_user_pool_endpoint" {
  description = "Cognito User Pool endpoint"
  value       = aws_cognito_user_pool.chat_user_pool.endpoint
}

# =================================================================
# DynamoDB Information
# =================================================================

output "dynamodb_room_table_name" {
  description = "DynamoDB Room table name"
  value       = aws_dynamodb_table.room.name
}

output "dynamodb_room_table_arn" {
  description = "DynamoDB Room table ARN"
  value       = aws_dynamodb_table.room.arn
}

output "dynamodb_message_table_name" {
  description = "DynamoDB Message table name"
  value       = aws_dynamodb_table.message.name
}

output "dynamodb_message_table_arn" {
  description = "DynamoDB Message table ARN"
  value       = aws_dynamodb_table.message.arn
}

# =================================================================
# Lambda Information
# =================================================================

output "lambda_sentiment_analysis_function_name" {
  description = "Lambda sentiment analysis function name"
  value       = aws_lambda_function.sentiment_analysis.function_name
}

output "lambda_sentiment_analysis_function_arn" {
  description = "Lambda sentiment analysis function ARN"
  value       = aws_lambda_function.sentiment_analysis.arn
}

# =================================================================
# Environment Information
# =================================================================

output "aws_region" {
  description = "AWS Region where resources are deployed"
  value       = var.aws_region
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}

# =================================================================
# Frontend Configuration (for React app)
# =================================================================

output "frontend_config" {
  description = "Configuration object for frontend applications"
  value = {
    aws_region               = var.aws_region
    appsync_graphql_endpoint = aws_appsync_graphql_api.chat_api.uris["GRAPHQL"]
    appsync_api_key          = var.environment != "prod" ? aws_appsync_api_key.chat_api_key[0].key : null
    cognito_user_pool_id     = aws_cognito_user_pool.chat_user_pool.id
    cognito_client_id        = aws_cognito_user_pool_client.chat_client.id
    cognito_identity_pool_id = aws_cognito_identity_pool.chat_identity_pool.id
    cognito_domain           = aws_cognito_user_pool_domain.chat_domain.domain
  }
  sensitive = true
}

# Amplify設定用の出力
output "amplify_config" {
  description = "Configuration for Amplify"
  value = {
    aws_project_region             = var.aws_region
    aws_appsync_graphqlEndpoint    = aws_appsync_graphql_api.chat_api.uris["GRAPHQL"]
    aws_appsync_region             = var.aws_region
    aws_appsync_authenticationType = "AMAZON_COGNITO_USER_POOLS"
    aws_cognito_region             = var.aws_region
    aws_user_pools_id              = aws_cognito_user_pool.chat_user_pool.id
    aws_user_pools_web_client_id   = aws_cognito_user_pool_client.chat_client.id
    aws_cognito_identity_pool_id   = aws_cognito_identity_pool.chat_identity_pool.id
  }
  sensitive = true
}

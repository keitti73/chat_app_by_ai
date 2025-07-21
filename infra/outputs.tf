# AppSync API 情報
output "appsync_graphql_endpoint" {
  description = "AppSync GraphQL endpoint"
  value       = aws_appsync_graphql_api.chat_api.uris["GRAPHQL"]
}

output "appsync_api_id" {
  description = "AppSync API ID"
  value       = aws_appsync_graphql_api.chat_api.id
}

output "appsync_api_key" {
  description = "AppSync API Key"
  value       = aws_appsync_api_key.chat_api_key.key
  sensitive   = true
}

# Cognito 情報
output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.chat_user_pool.id
}

output "cognito_user_pool_client_id" {
  description = "Cognito User Pool Client ID"
  value       = aws_cognito_user_pool_client.chat_client.id
}

output "cognito_identity_pool_id" {
  description = "Cognito Identity Pool ID"
  value       = aws_cognito_identity_pool.chat_identity_pool.id
}

# DynamoDB テーブル情報
output "room_table_name" {
  description = "Room table name"
  value       = aws_dynamodb_table.room.name
}

output "message_table_name" {
  description = "Message table name"
  value       = aws_dynamodb_table.message.name
}

# AWS Region
output "aws_region" {
  description = "AWS Region"
  value       = var.aws_region
}

# Amplify設定用の出力
output "amplify_config" {
  description = "Configuration for Amplify"
  value = {
    aws_project_region                = var.aws_region
    aws_appsync_graphqlEndpoint       = aws_appsync_graphql_api.chat_api.uris["GRAPHQL"]
    aws_appsync_region                = var.aws_region
    aws_appsync_authenticationType    = "AMAZON_COGNITO_USER_POOLS"
    aws_cognito_region               = var.aws_region
    aws_user_pools_id               = aws_cognito_user_pool.chat_user_pool.id
    aws_user_pools_web_client_id    = aws_cognito_user_pool_client.chat_client.id
    aws_cognito_identity_pool_id    = aws_cognito_identity_pool.chat_identity_pool.id
  }
  sensitive = true
}

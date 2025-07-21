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
    aws_appsync_authenticationType    = "API_KEY"
    aws_appsync_apiKey                = aws_appsync_api_key.chat_api_key.key
  }
  sensitive = true
}

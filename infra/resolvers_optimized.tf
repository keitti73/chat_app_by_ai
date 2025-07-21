# =================================================================
# AppSync Resolvers Configuration
# =================================================================
# GraphQLのクエリ、ミューテーション、サブスクリプションに対応するリゾルバー定義
# 効率的で保守性の高いリゾルバー設計を実装

# =================================================================
# Data Sources
# =================================================================

# DynamoDB Data Sources
resource "aws_appsync_datasource" "room_table" {
  api_id           = aws_appsync_graphql_api.chat_api.id
  name             = local.appsync_datasources.room_table.name
  service_role_arn = aws_iam_role.appsync_dynamodb.arn
  type             = local.appsync_datasources.room_table.type

  dynamodb_config {
    table_name = aws_dynamodb_table.room.name
  }
}

resource "aws_appsync_datasource" "message_table" {
  api_id           = aws_appsync_graphql_api.chat_api.id
  name             = local.appsync_datasources.message_table.name
  service_role_arn = aws_iam_role.appsync_dynamodb.arn
  type             = local.appsync_datasources.message_table.type

  dynamodb_config {
    table_name = aws_dynamodb_table.message.name
  }
}

# Lambda Data Source
resource "aws_appsync_datasource" "sentiment_lambda" {
  api_id           = aws_appsync_graphql_api.chat_api.id
  name             = local.appsync_datasources.sentiment_lambda.name
  service_role_arn = aws_iam_role.appsync_lambda.arn
  type             = local.appsync_datasources.sentiment_lambda.type

  lambda_config {
    function_arn = aws_lambda_function.sentiment_analysis.arn
  }
}

# =================================================================
# Standard Resolvers (Direct resolvers)
# =================================================================

resource "aws_appsync_resolver" "standard" {
  for_each = local.graphql_resolvers

  api_id = aws_appsync_graphql_api.chat_api.id
  field  = split(".", each.key)[1]
  type   = split(".", each.key)[0]

  data_source = each.value.data_source == "room_table" ? aws_appsync_datasource.room_table.name : (
    each.value.data_source == "message_table" ? aws_appsync_datasource.message_table.name :
    aws_appsync_datasource.sentiment_lambda.name
  )

  runtime {
    name            = "APPSYNC_JS"
    runtime_version = "1.0.0"
  }

  code = file(each.value.code_file)
}

# =================================================================
# Pipeline Resolvers (Multi-step resolvers)
# =================================================================

# Note: Pipeline resolverは複雑なため、必要に応じて個別に定義
# 現在はシンプルなリゾルバーのみ使用

# Example pipeline resolver implementation:
# resource "aws_appsync_function" "get_messages" {
#   api_id      = aws_appsync_graphql_api.chat_api.id
#   data_source = aws_appsync_datasource.message_table.name
#   name        = "getMessages"
#
#   runtime {
#     name            = "APPSYNC_JS"
#     runtime_version = "1.0.0"
#   }
#
#   code = file("${path.module}/../resolvers/Pipeline_myActiveRooms_1_getMessages.js")
# }

# =================================================================
# Subscriptions (Real-time updates)
# =================================================================

# Note: Subscription resolverは必要に応じて追加
# resource "aws_appsync_resolver" "subscription_message_added" {
#   api_id      = aws_appsync_graphql_api.chat_api.id
#   field       = "messageAdded"
#   type        = "Subscription"
#   data_source = aws_appsync_datasource.message_table.name
#
#   runtime {
#     name            = "APPSYNC_JS"
#     runtime_version = "1.0.0"
#   }
#
#   code = file("${path.module}/../resolvers/Subscription_messageAdded.js")
# }

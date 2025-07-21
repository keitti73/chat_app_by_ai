# =================================================================
# Local Values定義ファイル
# =================================================================
# 計算値や共通設定の定義
# 変数を組み合わせた値や、環境固有の設定を管理

locals {
  # =================================================================
  # Common Naming Convention
  # =================================================================
  name_prefix = "${var.project_name}-${var.environment}"

  # =================================================================
  # Common Tags
  # =================================================================
  common_tags = merge(var.common_tags, {
    Environment = var.environment
    Project     = var.project_name
    Region      = var.aws_region
    Timestamp   = timestamp()
  })

  # =================================================================
  # DynamoDB Configuration
  # =================================================================
  dynamodb_tables = {
    room = {
      name         = var.dynamodb_table_prefix != "" ? "${var.dynamodb_table_prefix}-Room" : "Room"
      hash_key     = "id"
      billing_mode = var.dynamodb_billing_mode
      attributes = [
        {
          name = "id"
          type = "S"
        },
        {
          name = "owner"
          type = "S"
        },
        {
          name = "createdAt"
          type = "S"
        }
      ]
      global_secondary_indexes = [
        {
          name            = "owner-index"
          hash_key        = "owner"
          projection_type = "ALL"
        }
      ]
    }

    message = {
      name         = var.dynamodb_table_prefix != "" ? "${var.dynamodb_table_prefix}-Message" : "Message"
      hash_key     = "id"
      billing_mode = var.dynamodb_billing_mode
      attributes = [
        {
          name = "id"
          type = "S"
        },
        {
          name = "roomId"
          type = "S"
        },
        {
          name = "user"
          type = "S"
        },
        {
          name = "createdAt"
          type = "S"
        }
      ]
      global_secondary_indexes = [
        {
          name            = "roomId-index"
          hash_key        = "roomId"
          range_key       = "createdAt"
          projection_type = "ALL"
        },
        {
          name            = "user-index"
          hash_key        = "user"
          projection_type = "ALL"
        }
      ]
    }
  }

  # =================================================================
  # Lambda Configuration
  # =================================================================
  lambda_functions = {
    sentiment_analysis = {
      name        = "${local.name_prefix}-sentiment-analysis"
      handler     = "analyzeMessageSentiment.handler"
      runtime     = var.lambda_runtime
      timeout     = var.lambda_timeout
      memory_size = var.lambda_memory_size
      source_file = "${path.module}/../lambda/analyzeMessageSentiment.js"
      environment_variables = {
        REGION      = var.aws_region
        ENABLE_XRAY = var.enable_xray_tracing ? "true" : "false"
      }
    }
  }

  # =================================================================
  # IAM Policy Documents
  # =================================================================
  lambda_assume_role_policy = jsonencode({
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

  appsync_assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "appsync.amazonaws.com"
        }
      }
    ]
  })

  # =================================================================
  # AppSync Configuration
  # =================================================================
  appsync_datasources = {
    room_table = {
      name = "RoomTable"
      type = "AMAZON_DYNAMODB"
    }
    message_table = {
      name = "MessageTable"
      type = "AMAZON_DYNAMODB"
    }
    sentiment_lambda = {
      name = "SentimentLambda"
      type = "AWS_LAMBDA"
    }
  }

  # =================================================================
  # GraphQL Resolvers Configuration
  # =================================================================
  graphql_resolvers = {
    # Mutations
    "Mutation.createRoom" = {
      data_source = "room_table"
      code_file   = "${path.module}/../resolvers/Mutation_createRoom.js"
    }
    "Mutation.postMessage" = {
      data_source = "message_table"
      code_file   = "${path.module}/../resolvers/Mutation_postMessage.js"
    }
    
    # Queries
    "Query.myOwnedRooms" = {
      data_source = "room_table"
      code_file   = "${path.module}/../resolvers/Query_myOwnedRooms.js"
    }
    "Query.getRoom" = {
      data_source = "room_table"
      code_file   = "${path.module}/../resolvers/Query_getRoom.js"
    }
    "Query.listMessages" = {
      data_source = "message_table"
      code_file   = "${path.module}/../resolvers/Query_listMessages.js"
    }
    
    # Lambda Resolvers (commented out until resolver files exist)
    # "Message.analyzeMessageSentiment" = {
    #   data_source = "sentiment_lambda"
    #   code_file   = "${path.module}/../resolvers/Lambda_analyzeMessageSentiment.js"
    # }
  }
}
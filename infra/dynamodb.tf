# =================================================================
# DynamoDB Tables Configuration
# =================================================================
# チャットアプリケーション用のDynamoDBテーブル定義
# 設計原則：
# - NoSQLのベストプラクティスに従った設計
# - アクセスパターンを考慮したGSI設計
# - コスト効率的な課金モード選択

# =================================================================
# Room Table
# =================================================================
# チャットルーム情報を管理するテーブル
resource "aws_dynamodb_table" "room" {
  name         = local.dynamodb_tables.room.name
  billing_mode = local.dynamodb_tables.room.billing_mode
  hash_key     = local.dynamodb_tables.room.hash_key

  # Attribute definitions
  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "owner"
    type = "S"
  }

  attribute {
    name = "createdAt"
    type = "S"
  }

  # Global Secondary Index for owner-based queries
  global_secondary_index {
    name            = "owner-index"
    hash_key        = "owner"
    projection_type = "ALL"
  }

  # Point-in-time recovery
  point_in_time_recovery {
    enabled = var.environment == "prod" ? true : false
  }

  # Server-side encryption
  server_side_encryption {
    enabled = true
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-room-table"
    Type = "DynamoDB"
  })
}

# =================================================================
# Message Table
# =================================================================
# チャットメッセージを管理するテーブル
resource "aws_dynamodb_table" "message" {
  name         = local.dynamodb_tables.message.name
  billing_mode = local.dynamodb_tables.message.billing_mode
  hash_key     = local.dynamodb_tables.message.hash_key

  # Attribute definitions
  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "roomId"
    type = "S"
  }

  attribute {
    name = "user"
    type = "S"
  }

  attribute {
    name = "createdAt"
    type = "S"
  }

  # Global Secondary Indexes for efficient querying
  global_secondary_index {
    name            = "roomId-index"
    hash_key        = "roomId"
    range_key       = "createdAt"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "user-index"
    hash_key        = "user"
    projection_type = "ALL"
  }

  # Time To Live (TTL) for automatic message cleanup
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  # Point-in-time recovery for production
  point_in_time_recovery {
    enabled = var.environment == "prod" ? true : false
  }

  # Server-side encryption
  server_side_encryption {
    enabled = true
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-message-table"
    Type = "DynamoDB"
  })
}

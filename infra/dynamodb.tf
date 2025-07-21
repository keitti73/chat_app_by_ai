# Roomテーブル
resource "aws_dynamodb_table" "room" {
  name         = "Room"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

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

  global_secondary_index {
    name            = "owner-index"
    hash_key        = "owner"
    projection_type = "ALL"
  }

  tags = {
    Name = "${var.project_name}-room-table"
  }
}

# Messageテーブル
resource "aws_dynamodb_table" "message" {
  name         = "Message"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

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

  global_secondary_index {
    name            = "user-index"
    hash_key        = "user"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "room-index"
    hash_key        = "roomId"
    range_key       = "createdAt"
    projection_type = "ALL"
  }

  tags = {
    Name = "${var.project_name}-message-table"
  }
}

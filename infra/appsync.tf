# AppSync GraphQL API
resource "aws_appsync_graphql_api" "chat_api" {
  authentication_type = "API_KEY"
  name                = "${var.project_name}-api"
  schema              = file("${path.module}/../schema.graphql")

  log_config {
    cloudwatch_logs_role_arn = aws_iam_role.appsync_logs.arn
    field_log_level          = "ERROR"
  }

  tags = {
    Name = "${var.project_name}-graphql-api"
  }
}

# AppSync API Key
resource "aws_appsync_api_key" "chat_api_key" {
  api_id      = aws_appsync_graphql_api.chat_api.id
  description = "API Key for ${var.project_name}"
  expires     = timeadd(timestamp(), "365d")
}

# IAM Role for AppSync CloudWatch Logs
resource "aws_iam_role" "appsync_logs" {
  name = "${var.project_name}-appsync-logs-role"

  assume_role_policy = jsonencode({
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
}

resource "aws_iam_role_policy" "appsync_logs" {
  name = "${var.project_name}-appsync-logs-policy"
  role = aws_iam_role.appsync_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# DynamoDB DataSource for Room table
resource "aws_appsync_datasource" "room_table" {
  api_id           = aws_appsync_graphql_api.chat_api.id
  name             = "RoomTable"
  service_role_arn = aws_iam_role.appsync_dynamodb.arn
  type             = "AMAZON_DYNAMODB"

  dynamodb_config {
    table_name = aws_dynamodb_table.room.name
  }
}

# DynamoDB DataSource for Message table
resource "aws_appsync_datasource" "message_table" {
  api_id           = aws_appsync_graphql_api.chat_api.id
  name             = "MessageTable"
  service_role_arn = aws_iam_role.appsync_dynamodb.arn
  type             = "AMAZON_DYNAMODB"

  dynamodb_config {
    table_name = aws_dynamodb_table.message.name
  }
}

# IAM Role for AppSync to access DynamoDB
resource "aws_iam_role" "appsync_dynamodb" {
  name = "${var.project_name}-appsync-dynamodb-role"

  assume_role_policy = jsonencode({
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
}

resource "aws_iam_role_policy" "appsync_dynamodb" {
  name = "${var.project_name}-appsync-dynamodb-policy"
  role = aws_iam_role.appsync_dynamodb.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:DeleteItem",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem"
        ]
        Resource = [
          aws_dynamodb_table.room.arn,
          "${aws_dynamodb_table.room.arn}/*",
          aws_dynamodb_table.message.arn,
          "${aws_dynamodb_table.message.arn}/*"
        ]
      }
    ]
  })
}

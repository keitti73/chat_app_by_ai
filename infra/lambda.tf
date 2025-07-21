# =================================================================
# Lambda Functions for Advanced Processing
# =================================================================
# 高度な処理が必要な機能をLambdaで実装
# JavaScript リゾルバーでは困難な以下の機能を提供：
# - AWS Comprehend連携による感情分析
# - 複雑な非同期処理制御
# - 外部API連携
# - 高度なエラーハンドリング

# Lambda実行ロール
resource "aws_iam_role" "lambda_sentiment_analysis_role" {
  name = "${var.project_name}-lambda-sentiment-analysis-role"

  assume_role_policy = jsonencode({
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

  tags = {
    Name        = "${var.project_name}-lambda-sentiment-analysis-role"
    Environment = var.environment
  }
}

# Lambda基本実行ポリシー
resource "aws_iam_role_policy_attachment" "lambda_sentiment_analysis_basic" {
  role       = aws_iam_role.lambda_sentiment_analysis_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# DynamoDB アクセスポリシー
resource "aws_iam_role_policy" "lambda_sentiment_analysis_dynamodb" {
  name = "${var.project_name}-lambda-sentiment-analysis-dynamodb"
  role = aws_iam_role.lambda_sentiment_analysis_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.room.arn,
          aws_dynamodb_table.message.arn,
          aws_dynamodb_table.sentiment_analysis.arn,
          "${aws_dynamodb_table.room.arn}/*",
          "${aws_dynamodb_table.message.arn}/*",
          "${aws_dynamodb_table.sentiment_analysis.arn}/*"
        ]
      }
    ]
  })
}

# AWS Comprehend アクセスポリシー
resource "aws_iam_role_policy" "lambda_sentiment_analysis_comprehend" {
  name = "${var.project_name}-lambda-sentiment-analysis-comprehend"
  role = aws_iam_role.lambda_sentiment_analysis_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "comprehend:DetectSentiment",
          "comprehend:DetectDominantLanguage",
          "comprehend:DetectEntities",
          "comprehend:DetectKeyPhrases"
        ]
        Resource = "*"
      }
    ]
  })
}

# 感情分析結果保存用DynamoDBテーブル
resource "aws_dynamodb_table" "sentiment_analysis" {
  name           = "${var.project_name}-sentiment-analysis"
  billing_mode   = "PAY_PER_REQUEST"  # オンデマンド課金
  hash_key       = "messageId"

  attribute {
    name = "messageId"
    type = "S"
  }

  # 分析日時でのクエリ用GSI
  attribute {
    name = "analyzedAt"
    type = "S"
  }

  global_secondary_index {
    name               = "analyzedAt-index"
    hash_key           = "analyzedAt"
    projection_type    = "ALL"
  }

  # TTL設定（分析結果の自動削除：90日後）
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = {
    Name        = "${var.project_name}-sentiment-analysis"
    Environment = var.environment
    Purpose     = "Store sentiment analysis results"
  }
}

# Lambda関数のZIPファイル作成
data "archive_file" "lambda_sentiment_analysis_zip" {
  type        = "zip"
  source_file = "${path.module}/../resolvers/Lambda_analyzeMessageSentiment.js"
  output_path = "${path.module}/lambda_sentiment_analysis.zip"
}

# Lambda関数
resource "aws_lambda_function" "sentiment_analysis" {
  filename         = data.archive_file.lambda_sentiment_analysis_zip.output_path
  function_name    = "${var.project_name}-sentiment-analysis"
  role            = aws_iam_role.lambda_sentiment_analysis_role.arn
  handler         = "Lambda_analyzeMessageSentiment.handler"
  runtime         = "nodejs18.x"
  timeout         = 30
  memory_size     = 256

  source_code_hash = data.archive_file.lambda_sentiment_analysis_zip.output_base64sha256

  environment {
    variables = {
      AWS_REGION                     = var.aws_region
      MESSAGE_TABLE_NAME            = aws_dynamodb_table.message.name
      SENTIMENT_ANALYSIS_TABLE_NAME = aws_dynamodb_table.sentiment_analysis.name
      LOG_LEVEL                     = "INFO"
    }
  }

  # デッドレターキュー（エラー時の処理）
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }

  tags = {
    Name        = "${var.project_name}-sentiment-analysis"
    Environment = var.environment
    Purpose     = "Analyze message sentiment using AWS Comprehend"
  }
}

# Lambda エラー処理用SQSキュー
resource "aws_sqs_queue" "lambda_dlq" {
  name                      = "${var.project_name}-lambda-dlq"
  message_retention_seconds = 1209600  # 14日間

  tags = {
    Name        = "${var.project_name}-lambda-dlq"
    Environment = var.environment
    Purpose     = "Dead letter queue for Lambda functions"
  }
}

# AppSync がLambdaを呼び出すためのロール
resource "aws_iam_role" "appsync_lambda_role" {
  name = "${var.project_name}-appsync-lambda-role"

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

  tags = {
    Name        = "${var.project_name}-appsync-lambda-role"
    Environment = var.environment
  }
}

# AppSync Lambda実行ポリシー
resource "aws_iam_role_policy" "appsync_lambda_policy" {
  name = "${var.project_name}-appsync-lambda-policy"
  role = aws_iam_role.appsync_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = aws_lambda_function.sentiment_analysis.arn
      }
    ]
  })
}

# AppSync Lambda データソース
resource "aws_appsync_datasource" "lambda_sentiment_analysis" {
  api_id           = aws_appsync_graphql_api.chat_api.id
  name             = "LambdaSentimentAnalysisDataSource"
  type             = "AWS_LAMBDA"
  service_role_arn = aws_iam_role.appsync_lambda_role.arn

  lambda_config {
    function_arn = aws_lambda_function.sentiment_analysis.arn
  }
}

# AppSync Lambda リゾルバー
resource "aws_appsync_resolver" "analyze_message_sentiment" {
  api_id      = aws_appsync_graphql_api.chat_api.id
  type        = "Query"
  field       = "analyzeMessageSentiment"
  data_source = aws_appsync_datasource.lambda_sentiment_analysis.name

  # Lambda呼び出し用のリクエストマッピング
  request_template = <<EOF
{
  "version": "2017-02-28",
  "operation": "Invoke",
  "payload": {
    "arguments": $util.toJson($context.arguments),
    "identity": $util.toJson($context.identity),
    "source": $util.toJson($context.source),
    "request": $util.toJson($context.request)
  }
}
EOF

  # Lambdaレスポンス用のレスポンスマッピング
  response_template = <<EOF
#if($context.error)
  $util.error($context.error.message, $context.error.type)
#else
  $util.toJson($context.result)
#end
EOF
}

# CloudWatch Logs for Lambda
resource "aws_cloudwatch_log_group" "lambda_sentiment_analysis_logs" {
  name              = "/aws/lambda/${aws_lambda_function.sentiment_analysis.function_name}"
  retention_in_days = 14

  tags = {
    Name        = "${var.project_name}-lambda-sentiment-analysis-logs"
    Environment = var.environment
  }
}

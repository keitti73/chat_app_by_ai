# =================================================================
# IAM Roles and Policies Configuration
# =================================================================
# 各AWSサービス間のアクセス権限を管理
# セキュリティのベストプラクティスに従った最小権限の原則を適用

# =================================================================
# AppSync IAM Role for DynamoDB Access
# =================================================================

resource "aws_iam_role" "appsync_dynamodb" {
  name               = "${local.name_prefix}-appsync-dynamodb-role"
  assume_role_policy = local.appsync_assume_role_policy

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-appsync-dynamodb-role"
    Type = "IAM-Role"
  })
}

resource "aws_iam_role_policy" "appsync_dynamodb" {
  name = "${local.name_prefix}-appsync-dynamodb-policy"
  role = aws_iam_role.appsync_dynamodb.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:GetItem",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:UpdateItem"
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

# =================================================================
# AppSync IAM Role for CloudWatch Logs
# =================================================================

resource "aws_iam_role" "appsync_logs" {
  name               = "${local.name_prefix}-appsync-logs-role"
  assume_role_policy = local.appsync_assume_role_policy

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-appsync-logs-role"
    Type = "IAM-Role"
  })
}

resource "aws_iam_role_policy" "appsync_logs" {
  name = "${local.name_prefix}-appsync-logs-policy"
  role = aws_iam_role.appsync_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:*"
      }
    ]
  })
}

# =================================================================
# Lambda IAM Role for Sentiment Analysis
# =================================================================

resource "aws_iam_role" "lambda_sentiment_analysis" {
  name               = "${local.name_prefix}-lambda-sentiment-analysis-role"
  assume_role_policy = local.lambda_assume_role_policy

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-lambda-sentiment-analysis-role"
    Type = "IAM-Role"
  })
}

# Lambda基本実行ポリシー
resource "aws_iam_role_policy_attachment" "lambda_sentiment_analysis_basic" {
  role       = aws_iam_role.lambda_sentiment_analysis.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# DynamDBアクセスポリシー
resource "aws_iam_role_policy" "lambda_sentiment_analysis_dynamodb" {
  name = "${local.name_prefix}-lambda-sentiment-analysis-dynamodb"
  role = aws_iam_role.lambda_sentiment_analysis.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query"
        ]
        Resource = [
          aws_dynamodb_table.message.arn,
          "${aws_dynamodb_table.message.arn}/*"
        ]
      }
    ]
  })
}

# AWS Comprehend アクセスポリシー（感情分析用）
resource "aws_iam_role_policy" "lambda_sentiment_analysis_comprehend" {
  count = var.enable_comprehend ? 1 : 0
  name  = "${local.name_prefix}-lambda-sentiment-analysis-comprehend"
  role  = aws_iam_role.lambda_sentiment_analysis.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "comprehend:DetectSentiment",
          "comprehend:DetectEntities",
          "comprehend:DetectKeyPhrases"
        ]
        Resource = "*"
      }
    ]
  })
}

# X-Ray トレーシングポリシー（オプション）
resource "aws_iam_role_policy_attachment" "lambda_sentiment_analysis_xray" {
  count      = var.enable_xray_tracing ? 1 : 0
  role       = aws_iam_role.lambda_sentiment_analysis.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

# =================================================================
# AppSync IAM Role for Lambda Invocation
# =================================================================

resource "aws_iam_role" "appsync_lambda" {
  name               = "${local.name_prefix}-appsync-lambda-role"
  assume_role_policy = local.appsync_assume_role_policy

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-appsync-lambda-role"
    Type = "IAM-Role"
  })
}

resource "aws_iam_role_policy" "appsync_lambda" {
  name = "${local.name_prefix}-appsync-lambda-policy"
  role = aws_iam_role.appsync_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = "arn:aws:lambda:${var.aws_region}:*:function:${local.lambda_functions.sentiment_analysis.name}"
      }
    ]
  })
}

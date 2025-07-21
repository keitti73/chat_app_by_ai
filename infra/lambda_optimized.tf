# =================================================================
# Lambda Functions Configuration
# =================================================================
# 高度な処理が必要な機能をLambdaで実装
# JavaScript リゾルバーでは困難な以下の機能を提供：
# - AWS Comprehend連携による感情分析
# - 複雑な非同期処理制御
# - 外部API連携
# - 高度なエラーハンドリング

# =================================================================
# CloudWatch Log Groups
# =================================================================

resource "aws_cloudwatch_log_group" "lambda_sentiment_analysis" {
  name              = "/aws/lambda/${local.lambda_functions.sentiment_analysis.name}"
  retention_in_days = var.environment == "prod" ? 30 : 7

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-lambda-sentiment-analysis-logs"
    Type = "CloudWatch-LogGroup"
  })
}

# =================================================================
# Lambda Function Package
# =================================================================

data "archive_file" "lambda_sentiment_analysis" {
  type        = "zip"
  source_file = local.lambda_functions.sentiment_analysis.source_file
  output_path = "${path.module}/.terraform/lambda_sentiment_analysis.zip"
}

# =================================================================
# Sentiment Analysis Lambda Function
# =================================================================

resource "aws_lambda_function" "sentiment_analysis" {
  filename         = data.archive_file.lambda_sentiment_analysis.output_path
  function_name    = local.lambda_functions.sentiment_analysis.name
  role             = aws_iam_role.lambda_sentiment_analysis.arn
  handler          = local.lambda_functions.sentiment_analysis.handler
  source_code_hash = data.archive_file.lambda_sentiment_analysis.output_base64sha256
  runtime          = local.lambda_functions.sentiment_analysis.runtime
  timeout          = local.lambda_functions.sentiment_analysis.timeout
  memory_size      = local.lambda_functions.sentiment_analysis.memory_size

  environment {
    variables = merge(
      local.lambda_functions.sentiment_analysis.environment_variables,
      {
        MESSAGE_TABLE_NAME = aws_dynamodb_table.message.name
        ENABLE_COMPREHEND  = var.enable_comprehend ? "true" : "false"
      }
    )
  }

  # X-Ray tracing configuration
  dynamic "tracing_config" {
    for_each = var.enable_xray_tracing ? [1] : []
    content {
      mode = "Active"
    }
  }

  # VPC configuration (if needed for enhanced security)
  # vpc_config {
  #   subnet_ids         = var.lambda_subnet_ids
  #   security_group_ids = var.lambda_security_group_ids
  # }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_sentiment_analysis_basic,
    aws_cloudwatch_log_group.lambda_sentiment_analysis
  ]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-sentiment-analysis-lambda"
    Type = "Lambda-Function"
  })
}

# =================================================================
# Lambda Function Permissions
# =================================================================

# AppSyncからLambda関数を呼び出すための権限
resource "aws_lambda_permission" "appsync_invoke_sentiment_analysis" {
  statement_id  = "AllowExecutionFromAppSync"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sentiment_analysis.function_name
  principal     = "appsync.amazonaws.com"
  source_arn    = "${aws_appsync_graphql_api.chat_api.arn}/*"
}

# =================================================================
# Lambda Function Aliases (for Blue/Green deployments)
# =================================================================

resource "aws_lambda_alias" "sentiment_analysis_live" {
  name             = "live"
  description      = "Live version of sentiment analysis function"
  function_name    = aws_lambda_function.sentiment_analysis.function_name
  function_version = "$LATEST"

  lifecycle {
    ignore_changes = [function_version]
  }
}

# =================================================================
# Lambda Function Reserved Concurrency (for production)
# =================================================================

resource "aws_lambda_provisioned_concurrency_config" "sentiment_analysis" {
  count                             = var.environment == "prod" ? 1 : 0
  function_name                     = aws_lambda_function.sentiment_analysis.function_name
  provisioned_concurrent_executions = 5
  qualifier                         = aws_lambda_alias.sentiment_analysis_live.name
}

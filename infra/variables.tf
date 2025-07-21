# =================================================================
# Variables定義ファイル
# =================================================================
# プロジェクト全体で使用される変数の集約管理
# このファイルで全ての変数を一元管理することで、
# 設定の変更や環境別の設定が容易になります

# =================================================================
# Basic Project Configuration
# =================================================================

variable "aws_region" {
  description = "AWS region where resources will be deployed"
  type        = string
  default     = "us-east-1"

  validation {
    condition = contains([
      "us-east-1", "us-east-2", "us-west-1", "us-west-2",
      "eu-west-1", "eu-west-2", "eu-central-1",
      "ap-northeast-1", "ap-southeast-1", "ap-south-1"
    ], var.aws_region)
    error_message = "AWS region must be a valid region."
  }
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "appsync-chat-app"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

# =================================================================
# DynamoDB Configuration
# =================================================================

variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode"
  type        = string
  default     = "PAY_PER_REQUEST"

  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.dynamodb_billing_mode)
    error_message = "DynamoDB billing mode must be either PAY_PER_REQUEST or PROVISIONED."
  }
}

variable "dynamodb_table_prefix" {
  description = "Prefix for DynamoDB table names"
  type        = string
  default     = ""
}

# =================================================================
# Cognito Configuration
# =================================================================

variable "cognito_password_minimum_length" {
  description = "Minimum password length for Cognito"
  type        = number
  default     = 8

  validation {
    condition     = var.cognito_password_minimum_length >= 6 && var.cognito_password_minimum_length <= 99
    error_message = "Password minimum length must be between 6 and 99."
  }
}

variable "cognito_auto_verified_attributes" {
  description = "Attributes to be auto-verified"
  type        = list(string)
  default     = ["email"]
}

# =================================================================
# AppSync Configuration
# =================================================================

variable "appsync_api_key_expires_days" {
  description = "Number of days until AppSync API key expires"
  type        = number
  default     = 365

  validation {
    condition     = var.appsync_api_key_expires_days >= 1 && var.appsync_api_key_expires_days <= 365
    error_message = "API key expiration must be between 1 and 365 days."
  }
}

variable "appsync_log_level" {
  description = "AppSync log level"
  type        = string
  default     = "ERROR"

  validation {
    condition     = contains(["NONE", "ERROR", "ALL"], var.appsync_log_level)
    error_message = "Log level must be one of: NONE, ERROR, ALL."
  }
}

# =================================================================
# Lambda Configuration
# =================================================================

variable "lambda_runtime" {
  description = "Lambda runtime version"
  type        = string
  default     = "nodejs18.x"
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 30

  validation {
    condition     = var.lambda_timeout >= 1 && var.lambda_timeout <= 900
    error_message = "Lambda timeout must be between 1 and 900 seconds."
  }
}

variable "lambda_memory_size" {
  description = "Lambda memory size in MB"
  type        = number
  default     = 128

  validation {
    condition     = var.lambda_memory_size >= 128 && var.lambda_memory_size <= 10240
    error_message = "Lambda memory size must be between 128 and 10240 MB."
  }
}

# =================================================================
# Tagging Strategy
# =================================================================

variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default = {
    Project   = "ChatApp"
    ManagedBy = "Terraform"
    Owner     = "DevOps"
  }
}

# =================================================================
# Feature Flags
# =================================================================

variable "enable_comprehend" {
  description = "Enable AWS Comprehend sentiment analysis"
  type        = bool
  default     = true
}

variable "enable_xray_tracing" {
  description = "Enable X-Ray tracing for Lambda functions"
  type        = bool
  default     = false
}

variable "enable_cloudwatch_insights" {
  description = "Enable CloudWatch insights for logs"
  type        = bool
  default     = false
}

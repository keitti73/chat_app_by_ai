# =================================================================
# Terraform メイン設定ファイル
# =================================================================
# Terraformとは「コードでAWSのサービスを作る」ためのツールです
# このファイルでは、どのクラウドサービス（AWS）を使うかや
# 基本的な設定を決めています

# =================================================================
# Terraform Configuration
# =================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend configuration for state management
  # 本番環境では、S3バックエンドを使用することを推奨
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "chat-app/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

# =================================================================
# Provider Configuration
# =================================================================

provider "aws" {
  region = var.aws_region

  # Default tags applied to all resources
  default_tags {
    tags = local.common_tags
  }
}

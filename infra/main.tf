# =================================================================
# Terraform メイン設定ファイル
# =================================================================
# Terraformとは「コードでAWSのサービスを作る」ためのツールです
# このファイルでは、どのクラウドサービス（AWS）を使うかや
# 基本的な設定を決めています

# Terraformに「どのサービスプロバイダー（雲サービス会社）を使うか」を教える
terraform {
  required_providers {
    # AWSを使うことを宣言
    aws = {
      source  = "hashicorp/aws"   # AWSのTerraform用ツールの場所
      version = "~> 5.0"          # バージョン5.x系を使用
    }
  }
}

# AWSプロバイダーの設定
# 「この設定でAWSに接続してね」という指示
provider "aws" {
  region = var.aws_region  # どの地域のAWSを使うかを変数で指定
}

# 変数の定義：AWS地域
# 変数とは「あとから値を変更できる設定項目」のことです
variable "aws_region" {
  description = "AWS region"          # この変数の説明
  type        = string                # 文字列タイプ
  default     = "us-east-1"          # デフォルト値（アメリカ東部）
}

# 変数の定義：プロジェクト名
# 作成するAWSリソースの名前の前につける文字列
variable "project_name" {
  description = "Project name"        # この変数の説明
  type        = string                # 文字列タイプ
  default     = "appsync-chat-app"   # デフォルト値
}

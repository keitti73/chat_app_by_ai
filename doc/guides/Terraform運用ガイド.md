# Terraform ベストプラクティス & 運用ガイド

## 目次

1. [ファイル構造とモジュール化](#ファイル構造とモジュール化)
2. [変数とバリデーション](#変数とバリデーション)
3. [状態管理とセキュリティ](#状態管理とセキュリティ)
4. [環境管理戦略](#環境管理戦略)
5. [CI/CD パイプライン](#cicd-パイプライン)
6. [監視とアラート](#監視とアラート)
7. [コスト最適化](#コスト最適化)
8. [セキュリティ強化](#セキュリティ強化)

## ファイル構造とモジュール化

### 現在の最適化されたファイル構造

```
infra/
├── main.tf                    # プロバイダー設定とTerraform設定
├── variables.tf               # 全変数定義（バリデーション付き）
├── locals.tf                  # 計算値とデータ変換
├── outputs.tf                 # 出力値（フロントエンド設定含む）
├── terraform.tfvars.example   # 設定テンプレート
│
├── iam.tf                     # IAM ロール・ポリシー
├── dynamodb.tf                # DynamoDB テーブル
├── cognito_optimized.tf       # Cognito 認証
├── appsync_optimized.tf       # AppSync GraphQL API
├── lambda_optimized.tf        # Lambda 関数
├── resolvers_optimized.tf     # GraphQL リゾルバー
│
└── resolver_templates/        # リゾルバーテンプレート
    └── pipeline_resolver.js.tpl
```

### ファイル分割の原則

1. **単一責任原則**: 各ファイルは特定のAWSサービスまたは機能に専念
2. **依存関係の明確化**: リソース間の依存関係を明確に定義
3. **再利用性**: テンプレートとモジュールの活用

## 変数とバリデーション

### 変数定義のベストプラクティス

```hcl
# ✅ 良い例：詳細な説明とバリデーション
variable "aws_region" {
  description = "AWS region where resources will be deployed"
  type        = string
  default     = "us-east-1"
  
  validation {
    condition = contains([
      "us-east-1", "us-east-2", "us-west-1", "us-west-2",
      "eu-west-1", "eu-west-2", "eu-central-1"
    ], var.aws_region)
    error_message = "AWS region must be a valid region."
  }
}

# ❌ 悪い例：説明不足、バリデーションなし
variable "region" {
  default = "us-east-1"
}
```

### 環境別設定戦略

```hcl
# locals.tf での環境別設定
locals {
  environment_config = {
    dev = {
      instance_type = "t3.micro"
      min_capacity  = 1
      max_capacity  = 2
    }
    staging = {
      instance_type = "t3.small"
      min_capacity  = 2
      max_capacity  = 4
    }
    prod = {
      instance_type = "t3.medium"
      min_capacity  = 3
      max_capacity  = 10
    }
  }
  
  current_config = local.environment_config[var.environment]
}
```

## 状態管理とセキュリティ

### リモートステート設定

```hcl
# main.tf
terraform {
  backend "s3" {
    bucket  = "your-terraform-state-bucket"
    key     = "chat-app/terraform.tfstate"
    region  = "us-east-1"
    
    # 状態ファイルの暗号化
    encrypt = true
    
    # 状態ロック用DynamoDBテーブル
    dynamodb_table = "terraform-state-lock"
    
    # バージョニング必須
    versioning = true
  }
}
```

### ステートファイルのセキュリティ

1. **暗号化**: S3バケットでの暗号化有効化
2. **アクセス制御**: IAMポリシーによる厳格なアクセス制御
3. **バージョニング**: 状態ファイルの履歴管理
4. **ロック機能**: 同時編集の防止

## 環境管理戦略

### Terraform Workspaces vs 別ディレクトリ

#### Workspaces使用（推奨）
```bash
# 環境の作成と切り替え
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# 環境固有の設定適用
terraform apply -var-file="environments/dev.tfvars"
```

#### 環境固有の設定ファイル

```
environments/
├── dev.tfvars
├── staging.tfvars
└── prod.tfvars
```

## CI/CD パイプライン

### GitHub Actions設定例

```yaml
# .github/workflows/terraform.yml
name: Terraform CI/CD

on:
  push:
    branches: [main, develop]
    paths: ['infra/**']
  pull_request:
    paths: ['infra/**']

env:
  TF_VERSION: "1.5.0"

jobs:
  terraform:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v2
      with:
        terraform_version: ${{ env.TF_VERSION }}
    
    - name: Terraform Format Check
      run: terraform fmt -check -recursive
      
    - name: Terraform Init
      run: terraform init
      working-directory: ./infra
      
    - name: Terraform Validate
      run: terraform validate
      working-directory: ./infra
      
    - name: Terraform Plan
      run: terraform plan -var-file="environments/${{ github.ref_name }}.tfvars"
      working-directory: ./infra
      
    - name: Terraform Apply
      if: github.ref == 'refs/heads/main'
      run: terraform apply -auto-approve -var-file="environments/prod.tfvars"
      working-directory: ./infra
```

### セキュリティ強化のCI/CD

```yaml
    - name: Security Scan
      uses: aquasecurity/trivy-action@master
      with:
        scan-type: 'config'
        scan-ref: './infra'
        
    - name: Cost Estimation
      uses: infracost/infracost-gh-action@v0.16
      with:
        path: ./infra
```

## 監視とアラート

### CloudWatchアラームの自動作成

```hcl
# monitoring.tf
resource "aws_cloudwatch_metric_alarm" "appsync_error_rate" {
  alarm_name          = "${local.name_prefix}-appsync-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "4XXError"
  namespace           = "AWS/AppSync"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "AppSync error rate is too high"
  
  dimensions = {
    GraphQLAPIId = aws_appsync_graphql_api.chat_api.id
  }
  
  alarm_actions = [aws_sns_topic.alerts.arn]
}
```

### コスト監視

```hcl
resource "aws_budgets_budget" "monthly_cost" {
  name         = "${local.name_prefix}-monthly-budget"
  budget_type  = "COST"
  limit_amount = "100"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  
  cost_filters = {
    Tag = ["Project:${var.project_name}"]
  }
  
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }
}
```

## コスト最適化

### DynamoDBコスト最適化

```hcl
# 環境別の設定
resource "aws_dynamodb_table" "optimized_table" {
  name         = local.dynamodb_tables.message.name
  billing_mode = var.environment == "prod" ? "PROVISIONED" : "PAY_PER_REQUEST"
  
  # 本番環境では予約キャパシティを使用
  read_capacity  = var.environment == "prod" ? 20 : null
  write_capacity = var.environment == "prod" ? 20 : null
  
  # 自動スケーリング（本番環境のみ）
  dynamic "auto_scaling_read" {
    for_each = var.environment == "prod" ? [1] : []
    content {
      max_capacity = 100
      min_capacity = 20
      target_value = 70
    }
  }
}
```

### Lambdaコスト最適化

```hcl
resource "aws_lambda_function" "cost_optimized" {
  # ARM64アーキテクチャでコスト削減
  architectures = ["arm64"]
  
  # 環境別メモリサイズ
  memory_size = var.environment == "prod" ? 512 : 128
  
  # 予約済み同時実行（本番環境のみ）
  reserved_concurrent_executions = var.environment == "prod" ? 10 : null
}
```

## セキュリティ強化

### IAMポリシーの最小権限

```hcl
# 具体的なリソースARNを指定
resource "aws_iam_role_policy" "lambda_specific_access" {
  name = "${local.name_prefix}-lambda-specific-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ]
        Resource = [
          aws_dynamodb_table.message.arn,
          "${aws_dynamodb_table.message.arn}/index/*"
        ]
        Condition = {
          StringEquals = {
            "dynamodb:LeadingKeys" = "$${cognito:sub}"
          }
        }
      }
    ]
  })
}
```

### 暗号化の強化

```hcl
# DynamoDB暗号化
resource "aws_dynamodb_table" "encrypted_table" {
  name = "SecureTable"
  
  server_side_encryption {
    enabled     = true
    kms_key_id = aws_kms_key.dynamodb_key.arn
  }
}

# KMSキーの作成
resource "aws_kms_key" "dynamodb_key" {
  description             = "DynamoDB encryption key"
  deletion_window_in_days = var.environment == "prod" ? 30 : 7
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM root permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}
```

## パフォーマンス最適化

### AppSync最適化

```hcl
resource "aws_appsync_graphql_api" "optimized_api" {
  name   = "${local.name_prefix}-api"
  schema = file("${path.module}/../schema.graphql")
  
  # キャッシング有効化
  cache_config {
    caching_behavior = "PER_RESOLVER_CACHING"
    ttl             = 300
    type            = "SMALL"
  }
  
  # 拡張ログ（デバッグ時のみ）
  log_config {
    cloudwatch_logs_role_arn = aws_iam_role.appsync_logs.arn
    field_log_level          = var.debug_mode ? "ALL" : "ERROR"
    exclude_verbose_content  = !var.debug_mode
  }
}
```

## 運用チェックリスト

### デプロイ前チェック

- [ ] `terraform fmt` でフォーマット確認
- [ ] `terraform validate` で構文チェック
- [ ] `terraform plan` で変更内容確認
- [ ] セキュリティスキャンの実行
- [ ] コスト影響の確認

### デプロイ後チェック

- [ ] リソースの正常性確認
- [ ] アプリケーションの動作確認
- [ ] ログの確認
- [ ] メトリクスの確認
- [ ] バックアップの確認

### 定期メンテナンス

- [ ] Terraformプロバイダーの更新
- [ ] セキュリティパッチの適用
- [ ] コスト分析とレビュー
- [ ] 不要なリソースのクリーンアップ
- [ ] ドキュメントの更新

## トラブルシューティング

### よくある問題と解決方法

#### 1. ステートファイルの競合
```bash
# ロックの解除
terraform force-unlock LOCK_ID

# ステートの修復
terraform refresh
```

#### 2. リソースのインポート
```bash
# 既存リソースのインポート
terraform import aws_dynamodb_table.example table-name
```

#### 3. プロバイダーの問題
```bash
# プロバイダーの再初期化
terraform init -upgrade
```

## 参考リンク

- [Terraform公式ドキュメント](https://www.terraform.io/docs)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

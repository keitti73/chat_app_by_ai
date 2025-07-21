# 🏗️ Terraformテンプレート

このファイルには、AWS AppSyncアプリケーションに新しいリソースを追加する際のTerraformテンプレートが含まれています。

## 🗄️ DynamoDBテーブルテンプレート

### 基本的なテーブル作成テンプレート

```hcl
# 🔹 基本的なDynamoDBテーブル
resource "aws_dynamodb_table" "your_entity_table" {
  name         = "${var.app_name}-your-entity"  # テーブル名
  billing_mode = "PAY_PER_REQUEST"              # 従量課金制（推奨）
  hash_key     = "id"                           # プライマリキー
  
  # 必要に応じてソートキーを追加
  # range_key    = "createdAt"                  # ソートキー（任意）

  # 🔹 属性定義（インデックスで使用する属性のみ定義）
  attribute {
    name = "id"                                 # プライマリキー
    type = "S"                                  # 文字列型 (S), 数値型 (N), バイナリ型 (B)
  }

  attribute {
    name = "userId"                             # ユーザーID（GSI用）
    type = "S"
  }

  attribute {
    name = "status"                             # ステータス（GSI用）
    type = "S"
  }

  attribute {
    name = "createdAt"                          # 作成日時（ソート用）
    type = "S"
  }

  # 🔹 グローバルセカンダリインデックス（GSI）
  # ユーザーID別検索用インデックス
  global_secondary_index {
    name            = "UserIdIndex"             # インデックス名
    hash_key        = "userId"                  # パーティションキー
    range_key       = "createdAt"               # ソートキー（任意）
    projection_type = "ALL"                     # 全属性を含める
    
    # 個別のキャパシティ設定（billing_modeがPROVISIONEDの場合）
    # read_capacity  = 5
    # write_capacity = 5
  }

  # ステータス別検索用インデックス
  global_secondary_index {
    name            = "StatusIndex"
    hash_key        = "status"
    range_key       = "createdAt"
    projection_type = "KEYS_ONLY"               # キーのみ含める（コスト削減）
  }

  # 🔹 ローカルセカンダリインデックス（LSI）- 同じパーティションキー内でのソート
  # local_secondary_index {
  #   name               = "CreatedAtIndex"
  #   range_key          = "createdAt"
  #   projection_type    = "ALL"
  # }

  # 🔹 Time To Live（TTL）設定 - 自動削除機能
  ttl {
    attribute_name = "expiresAt"                # TTL用の属性名
    enabled        = true
  }

  # 🔹 暗号化設定
  server_side_encryption {
    enabled = true                              # 保存時暗号化を有効
  }

  # 🔹 ポイントインタイムリカバリ（PITR）
  point_in_time_recovery {
    enabled = true                              # バックアップを有効
  }

  # 🔹 タグ設定
  tags = {
    Name        = "${var.app_name}-your-entity"
    Environment = var.environment
    Project     = var.app_name
    Purpose     = "エンティティデータ管理用テーブル"
    CreatedBy   = "Terraform"
  }
}
```

### 関連テーブル（多対多）テンプレート

```hcl
# 🔹 関連テーブル（多対多の関係を管理）
resource "aws_dynamodb_table" "entity_relations" {
  name         = "${var.app_name}-entity-relations"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "entityAId"
  range_key    = "entityBId"

  # 属性定義
  attribute {
    name = "entityAId"
    type = "S"
  }

  attribute {
    name = "entityBId"
    type = "S"
  }

  attribute {
    name = "relationType"
    type = "S"
  }

  # 逆方向検索用インデックス
  global_secondary_index {
    name            = "EntityBIndex"
    hash_key        = "entityBId"
    range_key       = "entityAId"
    projection_type = "ALL"
  }

  # 関連タイプ別検索用インデックス
  global_secondary_index {
    name            = "RelationTypeIndex"
    hash_key        = "relationType"
    range_key       = "entityAId"
    projection_type = "ALL"
  }

  tags = {
    Name        = "${var.app_name}-entity-relations"
    Environment = var.environment
    Purpose     = "エンティティ間の関連管理用テーブル"
  }
}
```

### 階層構造テーブルテンプレート

```hcl
# 🔹 階層構造管理テーブル
resource "aws_dynamodb_table" "hierarchical_entities" {
  name         = "${var.app_name}-hierarchical-entities"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "parentId"
    type = "S"
  }

  attribute {
    name = "level"
    type = "N"
  }

  attribute {
    name = "path"
    type = "S"
  }

  # 親ID別検索用インデックス
  global_secondary_index {
    name            = "ParentIdIndex"
    hash_key        = "parentId"
    range_key       = "id"
    projection_type = "ALL"
  }

  # レベル別検索用インデックス
  global_secondary_index {
    name            = "LevelIndex"
    hash_key        = "level"
    range_key       = "id"
    projection_type = "ALL"
  }

  # パス別検索用インデックス（前方一致検索用）
  global_secondary_index {
    name            = "PathIndex"
    hash_key        = "path"
    projection_type = "ALL"
  }

  tags = {
    Name        = "${var.app_name}-hierarchical-entities"
    Environment = var.environment
    Purpose     = "階層構造データ管理用テーブル"
  }
}
```

## 📡 AppSyncデータソーステンプレート

### DynamoDBデータソーステンプレート

```hcl
# 🔹 DynamoDB用データソース
resource "aws_appsync_datasource" "your_entity_table" {
  api_id           = aws_appsync_graphql_api.chat_api.id
  name             = "YourEntityTable"                    # データソース名（PascalCase）
  type             = "AMAZON_DYNAMODB"
  service_role_arn = aws_iam_role.appsync_role.arn

  dynamodb_config {
    table_name = aws_dynamodb_table.your_entity_table.name
    region     = data.aws_region.current.name
    
    # DynamoDB Accelerator (DAX) を使用する場合
    # use_caller_credentials = false
    # 
    # delta_sync_config {
    #   base_table_ttl        = 43200
    #   delta_sync_table_name = "${aws_dynamodb_table.your_entity_table.name}-delta"
    #   delta_sync_table_ttl  = 1440
    # }
  }
}
```

### Lambda データソーステンプレート

```hcl
# 🔹 Lambda関数用データソース
resource "aws_appsync_datasource" "lambda_function" {
  api_id           = aws_appsync_graphql_api.chat_api.id
  name             = "LambdaFunction"
  type             = "AWS_LAMBDA"
  service_role_arn = aws_iam_role.appsync_lambda_role.arn

  lambda_config {
    function_arn = aws_lambda_function.your_function.arn
  }
}

# Lambda関数の定義例
resource "aws_lambda_function" "your_function" {
  filename         = "function.zip"
  function_name    = "${var.app_name}-your-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "nodejs18.x"
  timeout         = 30

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.your_entity_table.name
      API_URL    = aws_appsync_graphql_api.chat_api.uris["GRAPHQL"]
    }
  }

  tags = {
    Name        = "${var.app_name}-your-function"
    Environment = var.environment
  }
}
```

### HTTP データソーステンプレート

```hcl
# 🔹 外部HTTP API用データソース
resource "aws_appsync_datasource" "external_api" {
  api_id = aws_appsync_graphql_api.chat_api.id
  name   = "ExternalAPI"
  type   = "HTTP"

  http_config {
    endpoint = "https://api.external-service.com"
    
    # 認証設定
    authorization_config {
      authorization_type = "AWS_IAM"
      
      # APIキー認証の場合
      # authorization_type = "API_KEY"
      # 
      # aws_iam_config {
      #   signing_region      = data.aws_region.current.name
      #   signing_service_name = "execute-api"
      # }
    }
  }
}
```

## 🔄 リゾルバーテンプレート

### 基本的なリゾルバーテンプレート

```hcl
# 🔹 Query用リゾルバー
resource "aws_appsync_resolver" "get_entity" {
  api_id      = aws_appsync_graphql_api.chat_api.id
  field       = "getEntity"                           # GraphQLスキーマのフィールド名
  type        = "Query"                               # Query, Mutation, Subscription
  data_source = aws_appsync_datasource.your_entity_table.name

  # JavaScriptリゾルバー（推奨）
  code = file("../resolvers/getEntity.js")
  runtime {
    name            = "APPSYNC_JS"
    runtime_version = "1.0.0"
  }

  # VTLリゾルバー（レガシー）
  # request_template  = file("../resolvers/getEntity-request.vtl")
  # response_template = file("../resolvers/getEntity-response.vtl")
}

# 🔹 Mutation用リゾルバー
resource "aws_appsync_resolver" "create_entity" {
  api_id      = aws_appsync_graphql_api.chat_api.id
  field       = "createEntity"
  type        = "Mutation"
  data_source = aws_appsync_datasource.your_entity_table.name

  code = file("../resolvers/createEntity.js")
  runtime {
    name            = "APPSYNC_JS"
    runtime_version = "1.0.0"
  }
}

# 🔹 Subscription用リゾルバー（Noneデータソース使用）
resource "aws_appsync_resolver" "on_entity_created" {
  api_id      = aws_appsync_graphql_api.chat_api.id
  field       = "onEntityCreated"
  type        = "Subscription"
  data_source = aws_appsync_datasource.none.name

  code = file("../resolvers/onEntityCreated.js")
  runtime {
    name            = "APPSYNC_JS"
    runtime_version = "1.0.0"
  }
}

# None データソース（Subscription用）
resource "aws_appsync_datasource" "none" {
  api_id = aws_appsync_graphql_api.chat_api.id
  name   = "None"
  type   = "NONE"
}
```

### パイプラインリゾルバーテンプレート

```hcl
# 🔹 パイプラインリゾルバー（複数のデータソースを組み合わせ）
resource "aws_appsync_resolver" "complex_query" {
  api_id = aws_appsync_graphql_api.chat_api.id
  field  = "complexQuery"
  type   = "Query"
  kind   = "PIPELINE"

  # パイプライン設定
  pipeline_config {
    functions = [
      aws_appsync_function.get_entity_data.function_id,
      aws_appsync_function.get_related_data.function_id,
      aws_appsync_function.format_response.function_id,
    ]
  }

  # パイプライン全体の制御コード
  code = file("../resolvers/pipeline/complexQuery.js")
  runtime {
    name            = "APPSYNC_JS"
    runtime_version = "1.0.0"
  }
}

# パイプライン関数の定義
resource "aws_appsync_function" "get_entity_data" {
  api_id                    = aws_appsync_graphql_api.chat_api.id
  data_source              = aws_appsync_datasource.your_entity_table.name
  name                     = "getEntityData"
  
  code = file("../resolvers/functions/getEntityData.js")
  runtime {
    name            = "APPSYNC_JS"
    runtime_version = "1.0.0"
  }
}

resource "aws_appsync_function" "get_related_data" {
  api_id                    = aws_appsync_graphql_api.chat_api.id
  data_source              = aws_appsync_datasource.related_table.name
  name                     = "getRelatedData"
  
  code = file("../resolvers/functions/getRelatedData.js")
  runtime {
    name            = "APPSYNC_JS"
    runtime_version = "1.0.0"
  }
}

resource "aws_appsync_function" "format_response" {
  api_id                    = aws_appsync_graphql_api.chat_api.id
  data_source              = aws_appsync_datasource.none.name
  name                     = "formatResponse"
  
  code = file("../resolvers/functions/formatResponse.js")
  runtime {
    name            = "APPSYNC_JS"
    runtime_version = "1.0.0"
  }
}
```

## 🔐 IAMロールテンプレート

### AppSync用IAMロールテンプレート

```hcl
# 🔹 AppSync用のIAMロール（DynamoDB操作権限）
resource "aws_iam_role" "appsync_dynamodb_role" {
  name = "${var.app_name}-appsync-dynamodb-role"

  # AppSyncサービスがこのロールを引き受けることを許可
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
    Name        = "${var.app_name}-appsync-dynamodb-role"
    Environment = var.environment
  }
}

# DynamoDB操作用のポリシー
resource "aws_iam_role_policy" "appsync_dynamodb_policy" {
  name = "${var.app_name}-appsync-dynamodb-policy"
  role = aws_iam_role.appsync_dynamodb_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem"
        ]
        Resource = [
          aws_dynamodb_table.your_entity_table.arn,
          "${aws_dynamodb_table.your_entity_table.arn}/index/*",
          # 他のテーブルも必要に応じて追加
        ]
      }
    ]
  })
}
```

### Lambda用IAMロールテンプレート

```hcl
# 🔹 Lambda関数用のIAMロール
resource "aws_iam_role" "lambda_role" {
  name = "${var.app_name}-lambda-role"

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
}

# Lambda基本実行ポリシーをアタッチ
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

# DynamoDB操作用のカスタムポリシー
resource "aws_iam_role_policy" "lambda_dynamodb_policy" {
  name = "${var.app_name}-lambda-dynamodb-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.your_entity_table.arn,
          "${aws_dynamodb_table.your_entity_table.arn}/index/*"
        ]
      }
    ]
  })
}
```

## 📤 アウトプット設定テンプレート

```hcl
# 🔹 outputs.tf に追加する内容

# DynamoDBテーブル情報
output "your_entity_table_name" {
  description = "YourEntity テーブル名"
  value       = aws_dynamodb_table.your_entity_table.name
}

output "your_entity_table_arn" {
  description = "YourEntity テーブル ARN"
  value       = aws_dynamodb_table.your_entity_table.arn
}

# データソース情報
output "your_entity_datasource_name" {
  description = "YourEntity データソース名"
  value       = aws_appsync_datasource.your_entity_table.name
}

# 新しい環境変数（フロントエンド用）
output "frontend_env_vars" {
  description = "フロントエンド用の環境変数"
  value = {
    # 既存の環境変数に追加
    VITE_YOUR_ENTITY_TABLE_NAME = aws_dynamodb_table.your_entity_table.name
    # 必要に応じて他の設定値も追加
  }
}
```

## 🚀 使用方法

1. **適切なテンプレートを選択**
   - 基本的なテーブル：基本DynamoDBテンプレート
   - 関連データ：関連テーブルテンプレート
   - 階層構造：階層構造テーブルテンプレート

2. **カスタマイズ**
   - `your_entity` を実際のエンティティ名に変更
   - 属性名やインデックス設定を調整
   - 必要な権限を IAM ロールに追加

3. **段階的デプロイ**
   ```bash
   # 変更内容を確認
   terraform plan
   
   # 適用
   terraform apply
   ```

---

**💡 このテンプレートを使って、AWSリソースを効率的に構築できます！**

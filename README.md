# AWS AppSync チャットアプリ

このプロジェクトは、AWS AppSync、DynamoDB、Reactを使用したリアルタイムチャットアプリです。

## 🚀 セットアップ

### 1. 依存関係のインストール
```bash
npm install
```

### 2. AWSリソースのデプロイ（Terraform）
```bash
# 自動デプロイスクリプトを使用
npm run deploy

# または手動で実行
cd infra
terraform init
terraform apply
```

### 3. 環境変数の設定
```bash
# .env.example をコピーして .env ファイルを作成
cp .env.example .env

# Terraform output から取得した値を .env に設定
# または src/App.jsx の amplifyConfig を直接更新
```

### 4. 開発サーバーの起動
```bash
npm run dev
```

## 📁 プロジェクト構成

```
├── src/
│   ├── components/
│   │   ├── MyRooms.jsx      # ルーム一覧画面
│   │   └── ChatRoom.jsx     # チャット画面
│   ├── graphql/
│   │   ├── queries.js       # GraphQLクエリ
│   │   ├── mutations.js     # GraphQLミューテーション
│   │   └── subscriptions.js # GraphQLサブスクリプション
│   ├── App.jsx              # メインアプリ
│   └── main.jsx             # エントリーポイント
├── infra/
│   ├── main.tf              # Terraform設定
│   ├── dynamodb.tf          # DynamoDB設定
│   ├── appsync.tf           # AppSync API設定
│   ├── resolvers.tf         # AppSyncリゾルバー設定
│   └── outputs.tf           # Terraform出力値
├── resolvers/               # AppSyncリゾルバー
├── schema.graphql           # GraphQLスキーマ
└── vite.config.js           # Vite設定
```

## 🛠 機能

- ✅ チャットルームの作成
- ✅ リアルタイムメッセージング
- ✅ ルーム一覧表示
- ✅ メッセージ履歴表示
- ✅ リアルタイム通知

## 📚 技術スタック

- **フロントエンド**: React + Vite
- **バックエンド**: AWS AppSync (GraphQL)
- **データベース**: Amazon DynamoDB
- **リアルタイム**: GraphQL Subscriptions
- **IaC**: Terraform
- **認証**: Amazon Cognito (TODO)

## 🔧 開発時の注意

1. **AWS認証情報**: AWS CLIで認証情報を設定してください
2. **環境変数**: `.env.example`をコピーして`.env`ファイルを作成し、Terraform outputの値を設定してください
3. **API認証**: 現在はAPI Keyを使用しています（本番環境ではCognitoを推奨）
4. **機密情報**: `.env`ファイルや`terraform.tfvars`などの機密情報は`.gitignore`で除外されています

## 🚀 デプロイ手順

### 1. AWS認証情報の設定
```bash
aws configure
```

### 2. AWSリソースのデプロイ
```bash
npm run deploy
```

### 3. 環境変数の設定
Terraform outputから出力される値を`.env`ファイルに設定:
```bash
cp .env.example .env
# .envファイルに実際の値を設定
```

### 4. アプリケーションの起動
```bash
npm run dev
```

## 📝 TODO

- [ ] Cognito認証の実装
- [ ] エラーハンドリングの改善
- [ ] UI/UXの向上
- [ ] テストの追加
- [ ] デプロイメント自動化

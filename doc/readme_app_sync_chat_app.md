# AWS AppSync×DynamoDB チャットアプリ README

---

## 概要

このプロジェクトは、AWSフルマネージド（AppSync, DynamoDB, Cognito, Lambda, S3）＋IaC（Terraform）＋React（Amplify）で実装するSlack風リアルタイム・チャットアプリの学習用リポジトリです。

---

## 主要構成

- **GraphQL API**: AppSync（スキーマ・リゾルバーJS）
- **データストア**: DynamoDB（Room/Messageテーブル＋GSI）
- **ユーザー認証**: Cognito
- **フロントエンド**: React＋Amplify v6
- **IaC**: Terraform
- **CI/CD**: GitHub Actions等（自動デプロイ可能）

---

## ディレクトリ構成例

```
.
├── amplify/                # Amplify CLI管理ディレクトリ
├── infra/                  # Terraform (main.tf, dynamodb.tf, ...)
├── resolvers/              # AppSync JSリゾルバー
├── src/
│   ├── components/
│   │   ├── ChatRoom.jsx    # チャットルーム画面
│   │   └── MyRooms.jsx     # 自分のルーム一覧
│   ├── graphql/            # GraphQLクエリ/Mutation/Subscription
│   └── aws-exports.js      # Amplify自動生成
└── schema.graphql          # GraphQLスキーマ
```

---

## 初期セットアップ

### 1. リポジトリクローン・依存関係

```sh
git clone <your-repo-url>
cd <your-project-dir>
npm install
```

### 2. AWSリソースのデプロイ（Terraform推奨）

```sh
cd infra
terraform init
terraform apply
```

### 3. Amplifyセットアップ（初回）

```sh
npx amplify@latest init
npx amplify@latest pull  # 既存AppSync連携用
```

### 4. ローカル開発起動

```sh
npm start
```

---

## GraphQLスキーマ要約

- Room型/Message型/Mutation（ルーム作成・投稿）/Query（自分のルーム・発言ルーム一覧、メッセージ一覧）/Subscription（新着リアルタイム通知）
- 詳細は`schema.graphql`参照

---

## DynamoDB設計のポイント

- Roomテーブル：owner-index（GSI）で「自分が作成したルーム」を高速検索
- Messageテーブル：user-index（GSI）で「自分が発言したルーム」を取得、room-indexで「ルームのメッセージ一覧＋時系列」取得

---

## AppSyncリゾルバー（例）

- JS関数としてリゾルバーロジックを記述（例：resolvers/Mutation\_postMessage.js等）
- owner-index, user-indexなどGSI検索も1行で実装可能
- 認証情報はctx.identityで参照

---

## フロントエンド実装例

- MyRooms.jsx：自分の参加/作成ルーム一覧
- ChatRoom.jsx：選択したroomIdのチャット画面（投稿・購読）
- Amplify generateClient() APIを使い、Mutation/Query/Subscriptionを共通で呼び出し

---

## CI/CD運用例

- push/PRでGitHub Actionsが`terraform apply`やAmplifyデプロイを自動実行
- スキーマ・リゾルバー・フロントコードの一元管理＆本番適用が容易

---

## 拡張・発展設計例

- 認可強化（IAM/owner権限）
- ファイル添付（S3）、絵文字・スタンプ、公開/非公開ルーム
- パフォーマンス最適化（DynamoDB設計見直し、Batch API活用）
- モバイル対応、ユニットテスト/型自動生成のCI/CD組込など

---

## ライセンス・問い合わせ

- 本リポジトリは学習・社内利用自由。
- ご不明点・拡張相談はIssueまたはコントリビューションへどうぞ。


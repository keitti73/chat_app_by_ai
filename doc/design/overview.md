# チャットアプリ - データベース設計とAPI設計書

## 1. システム概要

このチャットアプリは、リアルタイムメッセージング機能を提供するWebアプリケーションです。
以下の主要機能を持ちます：

- ユーザー認証（Amazon Cognito）
- チャットルームの作成・管理
- リアルタイムメッセージング
- メッセージ履歴の保存・取得

## 2. データベース設計

### 2.1 使用技術
- **データベース**: Amazon DynamoDB（NoSQLデータベース）
- **特徴**: サーバーレス、高可用性、自動スケーリング
- **課金方式**: Pay Per Request（使用量に応じた従量課金）

### 2.2 テーブル設計

#### 2.2.1 Roomテーブル（チャットルーム情報）

| 属性名 | データ型 | 説明 | 制約 |
|--------|----------|------|------|
| id | String (S) | ルームの一意識別子 | パーティションキー（主キー） |
| name | String | ルーム名 | 必須 |
| owner | String | ルーム作成者のユーザー名 | 必須、GSI1のパーティションキー |
| createdAt | String | ルーム作成日時（ISO8601形式） | 必須 |

**インデックス設計**:
- **Primary Key**: id（パーティションキー）
- **Global Secondary Index (GSI)**: owner-index
  - パーティションキー: owner
  - 用途: 特定ユーザーが作成したルーム一覧の取得

**アクセスパターン**:
1. ルームIDによる特定ルーム情報の取得
2. ユーザーが作成したルーム一覧の取得（owner-indexを使用）

#### 2.2.2 Messageテーブル（メッセージ情報）

| 属性名 | データ型 | 説明 | 制約 |
|--------|----------|------|------|
| id | String (S) | メッセージの一意識別子 | パーティションキー（主キー） |
| text | String | メッセージ本文 | 必須 |
| user | String | メッセージ投稿者のユーザー名 | 必須、GSI1のパーティションキー |
| roomId | String | 所属ルームのID | 必須、GSI2のパーティションキー |
| createdAt | String | メッセージ投稿日時（ISO8601形式） | 必須、GSI2のソートキー |

**インデックス設計**:
- **Primary Key**: id（パーティションキー）
- **Global Secondary Index 1**: user-index
  - パーティションキー: user
  - 用途: 特定ユーザーが投稿したメッセージ一覧の取得
- **Global Secondary Index 2**: room-index
  - パーティションキー: roomId
  - ソートキー: createdAt
  - 用途: 特定ルームのメッセージ一覧を時系列順で取得

**アクセスパターン**:
1. メッセージIDによる特定メッセージ情報の取得
2. 特定ユーザーが投稿したメッセージ一覧の取得（user-indexを使用）
3. 特定ルームのメッセージ一覧を時系列順で取得（room-indexを使用）

### 2.3 データモデリングの特徴

- **NoSQL設計**: リレーショナルデータベースとは異なり、結合を避けて非正規化したデータ構造
- **GSI活用**: 複数のアクセスパターンに対応するため、Global Secondary Indexを効果的に活用
- **時系列データ**: メッセージの時系列取得のため、createdAtをソートキーとして設計

## 3. API設計（GraphQL）

### 3.1 使用技術
- **API方式**: GraphQL
- **サービス**: AWS AppSync
- **認証**: Amazon Cognito User Pool
- **リアルタイム通信**: GraphQL Subscription

### 3.2 スキーマ設計

#### 3.2.1 データ型定義

**Message型**:
```graphql
type Message {
  id: ID!              # メッセージの一意識別子
  text: String!        # メッセージ本文
  user: String!        # 投稿者ユーザー名
  createdAt: AWSDateTime!  # 投稿日時
  roomId: ID!          # 所属ルームID
}
```

**Room型**:
```graphql
type Room {
  id: ID!              # ルームの一意識別子
  name: String!        # ルーム名
  owner: String!       # 作成者ユーザー名
  createdAt: AWSDateTime!  # 作成日時
  messages: [Message]  # 関連メッセージ（オプション）
}
```

#### 3.2.2 Query（データ取得操作）

| クエリ名 | 引数 | 戻り値 | 説明 |
|----------|------|--------|------|
| myOwnedRooms | なし | [Room] | 認証ユーザーが作成したルーム一覧 |
| myActiveRooms | なし | [Room] | 認証ユーザーが参加しているルーム一覧 |
| getRoom | id: ID! | Room | 指定されたIDのルーム情報 |
| listMessages | roomId: ID!, limit: Int | [Message] | 指定ルームのメッセージ一覧 |

**実装例（myOwnedRooms）**:
```javascript
// Request関数: DynamoDBクエリを構築
export function request(ctx) {
  const username = ctx.identity?.username;
  if (!username) {
    util.error("認証ユーザーのみ", "UnauthorizedError");
  }
  
  return {
    operation: "Query",
    query: {
      expression: "owner = :owner",
      expressionValues: util.dynamodb.toMapValues({
        ":owner": username
      })
    },
    index: "owner-index"  // GSIを使用
  };
}

// Response関数: 結果を加工して返却
export function response(ctx) {
  if (ctx.error) {
    util.error(ctx.error.message, ctx.error.type);
  }
  return ctx.result.items;
}
```

#### 3.2.3 Mutation（データ変更操作）

| ミューテーション名 | 引数 | 戻り値 | 説明 |
|-------------------|------|--------|------|
| createRoom | name: String! | Room | 新しいチャットルームを作成 |
| postMessage | roomId: ID!, text: String! | Message | 指定ルームにメッセージを投稿 |

**実装例（createRoom）**:
```javascript
export function request(ctx) {
  const username = ctx.identity?.username || "guest";
  const id = util.uuid();
  const createdAt = util.time.nowISO8601();
  
  return {
    operation: 'PutItem',
    key: util.dynamodb.toMapValues({ id }),
    attributeValues: util.dynamodb.toMapValues({
      id,
      name: ctx.args.name,
      owner: username,
      createdAt
    })
  };
}
```

#### 3.2.4 Subscription（リアルタイム通知）

| サブスクリプション名 | 引数 | 戻り値 | 説明 |
|---------------------|------|--------|------|
| onRoomCreated | なし | Room | 新しいルームが作成された時の通知 |
| onMessagePosted | roomId: ID! | Message | 指定ルームに新しいメッセージが投稿された時の通知 |

**実装例**:
```graphql
type Subscription {
  # createRoomミューテーションが実行された時に通知
  onRoomCreated: Room @aws_subscribe(mutations: ["createRoom"])
  
  # postMessageミューテーションが実行された時に通知
  onMessagePosted(roomId: ID!): Message @aws_subscribe(mutations: ["postMessage"])
}
```

### 3.3 認証・認可設計

- **認証方式**: Amazon Cognito User Pool
- **認証制御**: すべてのAPI操作で認証必須
- **認可制御**: 
  - ユーザーは自分が作成したルームと参加したルームのみアクセス可能
  - メッセージ投稿は認証ユーザーのみ

### 3.4 エラーハンドリング

- **UnauthorizedError**: 未認証ユーザーのアクセス時
- **ValidationError**: 入力値不正時
- **DynamoDBError**: データベースアクセスエラー時

## 4. データフロー

### 4.1 ルーム作成フロー
1. フロントエンド: `createRoom` Mutationを実行
2. AppSync: 認証チェック
3. Resolver: Roomテーブルに新規レコード挿入
4. AppSync: `onRoomCreated` Subscriptionで全クライアントに通知

### 4.2 メッセージ投稿フロー
1. フロントエンド: `postMessage` Mutationを実行
2. AppSync: 認証チェック
3. Resolver: Messageテーブルに新規レコード挿入
4. AppSync: `onMessagePosted` Subscriptionで該当ルーム参加者に通知

### 4.3 アクティブルーム取得フロー
1. フロントエンド: `myActiveRooms` Queryを実行
2. AppSync: 認証チェック
3. Resolver: Messageテーブル（user-index）からユーザーのメッセージを取得
4. Resolver: 重複排除してユニークなroomIdを抽出
5. フロントエンド: 各ルームの詳細情報を個別に取得

## 5. 現在の構成

### 5.1 DynamoDB設定
- **Room Table**: プライマリーキー（id）、GSI（owner-index）
- **Message Table**: プライマリーキー（id）、GSI（user-index, room-index）
- **Capacity Mode**: On-Demand（自動スケーリング）

### 5.2 GraphQL API
- **認証**: Cognito User Pool
- **認可**: フィールドレベルでの権限制御
- **リアルタイム**: WebSocket Subscriptions

## 6. 監視・運用
- **地理的分散**: CloudFrontによるエッジ配信

## 7. セキュリティ考慮事項

### 7.1 認証・認可
- **JWT検証**: Cognito User Poolによるトークン検証
- **ロールベースアクセス**: IAMロールによる最小権限の原則
- **CORS設定**: オリジン制限によるセキュリティ強化

### 7.2 データ保護
- **暗号化**: DynamoDB保存時暗号化（KMS）
- **転送時暗号化**: HTTPS/WSS通信の強制
- **ログ監査**: CloudTrailによるアクセスログ記録

## 8. 監視・運用

### 8.1 メトリクス監視
- **DynamoDB**: 読み書きスループット、エラー率
- **AppSync**: API呼び出し回数、レスポンス時間、エラー率
- **Cognito**: 認証成功率、失敗率

### 8.2 アラート設定
- **エラー率閾値**: 5%以上でアラート
- **レスポンス時間**: 3秒以上でアラート
- **スループット**: 80%以上でアラート

## 9. 今後の拡張予定

### 9.1 機能拡張
- **ファイル共有**: S3連携による画像・ファイル送信
- **プッシュ通知**: モバイルアプリ向け通知機能
- **検索機能**: Elasticsearch連携による全文検索

# ドキュメント分割について

このドキュメントは、より詳細で専門的な内容のために以下のファイルに分割されました：

## 📁 分割されたドキュメント

### 1. **データベース設計詳細.md**
- DynamoDBの詳細設計
- NoSQL設計原則
- パフォーマンス最適化
- 監視・運用戦略
- セキュリティ設計

### 2. **API設計詳細.md**
- GraphQL API の詳細設計
- Resolver実装パターン
- 認証・認可設計
- パフォーマンス最適化
- リアルタイム機能設計

### 3. **システムアーキテクチャ図集.md**
- 全体アーキテクチャ図
- セキュリティアーキテクチャ
- 監視・ログアーキテクチャ
- 災害復旧・バックアップ
- CI/CDパイプライン

### 4. **データフロー設計書.md**
- 基本データフロー
- 認証・認可フロー
- メッセージングフロー
- エラーハンドリングフロー
- パフォーマンス監視フロー

## 🎯 各ドキュメントの特徴

- **詳細な技術仕様**: 実装レベルの詳細情報
- **豊富なMermaid図**: 視覚的でわかりやすい説明
- **実践的な内容**: 実際のコードベースに基づいた設計
- **保守性重視**: 将来の拡張や変更を考慮した設計

各ドキュメントは独立して読むことができ、必要に応じて関連ドキュメントを参照することで、システム全体の理解を深めることができます。

---

*より詳細な情報については、上記の分割されたドキュメントをご参照ください。*

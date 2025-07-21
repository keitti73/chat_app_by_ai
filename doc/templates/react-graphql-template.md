# 📡 React GraphQL操作テンプレート

このファイルには、AWS AppSync と連携するReactアプリケーションのGraphQL操作（クエリ、ミューテーション、サブスクリプション）のテンプレートが含まれています。
**AWS Amplify v6** の `generateClient` を使用した実装例です。

## 📖 クエリテンプレート（src/graphql/queries.js）

```javascript
/**
 * 📖 GraphQLクエリ定義
 * データ取得用のクエリを定義します
 * AWS Amplify v6 の generateClient で使用
 */

// 🔍 単一エンティティ取得
export const getEntity = /* GraphQL */ `
  query GetEntity($id: ID!) {
    getEntity(id: $id) {
      id                    # エンティティID
      name                  # 名前
      description           # 説明
      status                # ステータス
      userId                # 作成者ID
      createdAt             # 作成日時
      updatedAt             # 更新日時
      version               # バージョン（楽観的ロック用）
      
      # 関連データも必要に応じて取得
      relatedItems {
        id
        name
        createdAt
      }
      
      # 統計情報
      itemCount             # 関連アイテム数
    }
  }
`;

// 📋 エンティティ一覧取得
export const listEntities = /* GraphQL */ `
  query ListEntities($userId: String, $status: EntityStatus, $limit: Int, $nextToken: String) {
    listEntities(userId: $userId, status: $status, limit: $limit, nextToken: $nextToken) {
      id
      name
      description
      status
      userId
      createdAt
      updatedAt
      itemCount
    }
  }
`;

// 🔍 ユーザー別エンティティ取得
export const listEntitiesByUser = /* GraphQL */ `
  query ListEntitiesByUser($userId: String!, $limit: Int, $nextToken: String) {
    listEntitiesByUser(userId: $userId, limit: $limit, nextToken: $nextToken) {
      id
      name
      description
      status
      createdAt
      updatedAt
    }
  }
`;

// 🔍 検索クエリ
export const searchEntities = /* GraphQL */ `
  query SearchEntities($keyword: String!, $limit: Int) {
    searchEntities(keyword: $keyword, limit: $limit) {
      id
      name
      description
      status
      createdAt
      # 検索結果には基本情報のみ含める
    }
  }
`;

// 📊 統計データ取得
export const getEntityStats = /* GraphQL */ `
  query GetEntityStats($userId: String) {
    getEntityStats(userId: $userId) {
      total                 # 総数
      activeCount           # アクティブ数
      inactiveCount         # 非アクティブ数
      todayCreated          # 今日作成された数
      recentItems {         # 最近のアイテム
        id
        name
        createdAt
      }
    }
  }
`;
```

## ✏️ ミューテーションテンプレート（src/graphql/mutations.js）

```javascript
/**
 * ✏️ GraphQLミューテーション定義
 * データ変更用のミューテーションを定義します
 * AWS Amplify v6 の generateClient で使用
 */

// 📝 エンティティ作成
export const createEntity = /* GraphQL */ `
  mutation CreateEntity($input: CreateEntityInput!) {
    createEntity(input: $input) {
      id                    # 作成されたエンティティのID
      name                  # 名前
      description           # 説明
      status                # ステータス
      userId                # 作成者ID
      createdAt             # 作成日時
      updatedAt             # 更新日時
      version               # バージョン
    }
  }
`;

// ✏️ エンティティ更新
export const updateEntity = /* GraphQL */ `
  mutation UpdateEntity($input: UpdateEntityInput!) {
    updateEntity(input: $input) {
      id                    # 更新されたエンティティのID
      name                  # 新しい名前
      description           # 新しい説明
      status                # 新しいステータス
      userId                # 作成者ID
      createdAt             # 作成日時
      updatedAt             # 更新日時
      version               # 新しいバージョン
    }
  }
`;

// 🗑️ エンティティ削除
export const deleteEntity = /* GraphQL */ `
  mutation DeleteEntity($id: ID!) {
    deleteEntity(id: $id) {
      id                    # 削除されたエンティティのID
      name                  # 削除されたエンティティの名前
      deletedAt: updatedAt  # 削除日時
    }
  }
`;

// 🔄 ステータス変更
export const activateEntity = /* GraphQL */ `
  mutation ActivateEntity($id: ID!) {
    activateEntity(id: $id) {
      id
      name
      status                # 'ACTIVE' になる
      updatedAt
    }
  }
`;

export const deactivateEntity = /* GraphQL */ `
  mutation DeactivateEntity($id: ID!) {
    deactivateEntity(id: $id) {
      id
      name
      status                # 'INACTIVE' になる
      updatedAt
    }
  }
`;

// 📎 関連付け操作
export const addEntityToUser = /* GraphQL */ `
  mutation AddEntityToUser($entityId: ID!, $userId: String!) {
    addEntityToUser(entityId: $entityId, userId: $userId) {
      id
      name
      userId                # 新しい所有者ID
      updatedAt
    }
  }
`;
```

## 🔔 サブスクリプションテンプレート（src/graphql/subscriptions.js）

```javascript
/**
 * 🔔 GraphQLサブスクリプション定義
 * リアルタイム通知用のサブスクリプションを定義します
 * AWS Amplify v6 の generateClient で使用
 */

// 📢 エンティティ作成時の通知
export const onEntityCreated = /* GraphQL */ `
  subscription OnEntityCreated($userId: String) {
    onEntityCreated(userId: $userId) {
      id
      name
      description
      status
      userId
      createdAt
    }
  }
`;

// 📝 エンティティ更新時の通知
export const onEntityUpdated = /* GraphQL */ `
  subscription OnEntityUpdated($id: ID!) {
    onEntityUpdated(id: $id) {
      id
      name
      description
      status
      updatedAt
      version
    }
  }
`;

// 🗑️ エンティティ削除時の通知
export const onEntityDeleted = /* GraphQL */ `
  subscription OnEntityDeleted($userId: String) {
    onEntityDeleted(userId: $userId) {
      id
      name
      deletedAt: updatedAt
    }
  }
`;

// 🔄 ステータス変更時の通知
export const onEntityStatusChanged = /* GraphQL */ `
  subscription OnEntityStatusChanged($id: ID!) {
    onEntityStatusChanged(id: $id) {
      id
      name
      status
      updatedAt
    }
  }
`;
```

## 🎯 使用方法

### 1. ファイルの配置
```
src/
├── graphql/
│   ├── queries.js      # クエリ定義
│   ├── mutations.js    # ミューテーション定義
│   └── subscriptions.js # サブスクリプション定義
```

### 2. コンポーネントでの使用例
```javascript
import { generateClient } from 'aws-amplify/api';
import { getEntity, listEntities } from './graphql/queries';
import { createEntity, updateEntity } from './graphql/mutations';
import { onEntityCreated } from './graphql/subscriptions';

const client = generateClient();

// クエリの実行
const { data } = await client.graphql({
  query: getEntity,
  variables: { id: 'entity-123' }
});

// ミューテーションの実行
const result = await client.graphql({
  query: createEntity,
  variables: { 
    input: { 
      name: 'New Entity',
      description: 'Description here'
    }
  }
});

// サブスクリプションの購読
const subscription = client.graphql({
  query: onEntityCreated,
  variables: { userId: 'user-123' }
}).subscribe({
  next: (data) => {
    console.log('New entity created:', data.data.onEntityCreated);
  }
});
```

## 🔗 関連テンプレート

- [React コンポーネントテンプレート](./react-components-template.md) - UIコンポーネントの実装
- [React フォームテンプレート](./react-forms-template.md) - フォーム処理の実装
- [React スタイリングテンプレート](./react-styling-template.md) - CSSとUIパターン

# 🧠 JavaScript リゾルバー基本操作テンプレート

このファイルには、AWS AppSyncで使用する基本的なCRUD操作のJavaScriptリゾルバーテンプレートが含まれています。
**DynamoDB** との連携に特化した実装例です。

## 📖 基本的なCRUD操作リゾルバー

### 🔍 単一アイテム取得（GetItem）

```javascript
/**
 * 🔍 単一アイテム取得リゾルバー
 * DynamoDB GetItem オペレーション
 * 認証とエラーハンドリングを含む
 */

export function request(ctx) {
  console.log('GetItem request:', JSON.stringify(ctx, null, 2));
  
  // 🔒 認証チェック
  const { identity } = ctx;
  if (!identity || !identity.username) {
    throw new Error('認証が必要です');
  }

  // 📝 リクエストパラメータの検証
  const { id } = ctx.args;
  if (!id) {
    throw new Error('IDは必須パラメータです');
  }

  // 🔍 DynamoDB GetItem リクエスト
  return {
    operation: 'GetItem',
    key: {
      id: { S: id }
    },
    // 一貫性のある読み取り（強い整合性）
    consistentRead: true
  };
}

export function response(ctx) {
  console.log('GetItem response:', JSON.stringify(ctx, null, 2));
  
  // 🚨 DynamoDBエラーハンドリング
  if (ctx.error) {
    console.error('DynamoDB GetItem error:', ctx.error);
    throw new Error(`アイテムの取得に失敗しました: ${ctx.error.message}`);
  }

  // 📋 結果の確認
  const { result } = ctx;
  if (!result || Object.keys(result).length === 0) {
    // アイテムが見つからない場合はnullを返す
    return null;
  }

  // 🔄 DynamoDB属性の型変換
  return {
    id: result.id?.S,
    name: result.name?.S,
    description: result.description?.S,
    status: result.status?.S,
    userId: result.userId?.S,
    createdAt: result.createdAt?.S,
    updatedAt: result.updatedAt?.S,
    version: result.version?.N ? parseInt(result.version.N) : 1
  };
}
```

### 📝 アイテム作成（PutItem）

```javascript
/**
 * 📝 アイテム作成リゾルバー
 * DynamoDB PutItem オペレーション
 * UUID生成、タイムスタンプ、バリデーション含む
 */

import { util } from '@aws-appsync/utils';

export function request(ctx) {
  console.log('CreateItem request:', JSON.stringify(ctx, null, 2));
  
  // 🔒 認証チェック
  const { identity } = ctx;
  if (!identity || !identity.username) {
    throw new Error('認証が必要です');
  }

  // 📝 入力データの検証
  const { input } = ctx.args;
  if (!input) {
    throw new Error('入力データが必要です');
  }

  // 必須フィールドのバリデーション
  if (!input.name || input.name.trim().length === 0) {
    throw new Error('名前は必須です');
  }

  if (input.name.length > 100) {
    throw new Error('名前は100文字以内で入力してください');
  }

  if (input.description && input.description.length > 500) {
    throw new Error('説明は500文字以内で入力してください');
  }

  // 🆔 ID生成とタイムスタンプ
  const id = util.autoId();
  const now = util.time.nowISO8601();
  const username = identity.username;

  // 📊 DynamoDB PutItem リクエスト
  return {
    operation: 'PutItem',
    key: {
      id: { S: id }
    },
    attributeValues: {
      id: { S: id },
      name: { S: input.name.trim() },
      description: { S: input.description?.trim() || '' },
      status: { S: input.status || 'ACTIVE' },
      userId: { S: username },
      createdAt: { S: now },
      updatedAt: { S: now },
      version: { N: '1' }
    },
    // 🔒 条件付き書き込み（IDの重複防止）
    condition: {
      expression: 'attribute_not_exists(id)'
    }
  };
}

export function response(ctx) {
  console.log('CreateItem response:', JSON.stringify(ctx, null, 2));
  
  // 🚨 DynamoDBエラーハンドリング
  if (ctx.error) {
    console.error('DynamoDB PutItem error:', ctx.error);
    
    // 条件チェック失敗（重複ID）
    if (ctx.error.type === 'ConditionalCheckFailedException') {
      throw new Error('IDが既に存在します');
    }
    
    throw new Error(`アイテムの作成に失敗しました: ${ctx.error.message}`);
  }

  // ✅ 作成されたアイテムを返す
  const { result } = ctx;
  return {
    id: result.id?.S,
    name: result.name?.S,
    description: result.description?.S,
    status: result.status?.S,
    userId: result.userId?.S,
    createdAt: result.createdAt?.S,
    updatedAt: result.updatedAt?.S,
    version: result.version?.N ? parseInt(result.version.N) : 1
  };
}
```

### ✏️ アイテム更新（UpdateItem）

```javascript
/**
 * ✏️ アイテム更新リゾルバー
 * DynamoDB UpdateItem オペレーション
 * 楽観的ロック、差分更新対応
 */

import { util } from '@aws-appsync/utils';

export function request(ctx) {
  console.log('UpdateItem request:', JSON.stringify(ctx, null, 2));
  
  // 🔒 認証チェック
  const { identity } = ctx;
  if (!identity || !identity.username) {
    throw new Error('認証が必要です');
  }

  // 📝 入力データの検証
  const { input } = ctx.args;
  if (!input || !input.id) {
    throw new Error('IDは必須です');
  }

  // バリデーション
  if (input.name && input.name.trim().length === 0) {
    throw new Error('名前は必須です');
  }

  if (input.name && input.name.length > 100) {
    throw new Error('名前は100文字以内で入力してください');
  }

  if (input.description && input.description.length > 500) {
    throw new Error('説明は500文字以内で入力してください');
  }

  // 🔄 更新式の構築（差分更新）
  const expressionNames = {};
  const expressionValues = {};
  const updateExpressions = [];

  if (input.name !== undefined) {
    expressionNames['#name'] = 'name';
    expressionValues[':name'] = { S: input.name.trim() };
    updateExpressions.push('#name = :name');
  }

  if (input.description !== undefined) {
    expressionNames['#description'] = 'description';
    expressionValues[':description'] = { S: input.description.trim() };
    updateExpressions.push('#description = :description');
  }

  if (input.status !== undefined) {
    expressionNames['#status'] = 'status';
    expressionValues[':status'] = { S: input.status };
    updateExpressions.push('#status = :status');
  }

  // 必須更新フィールド
  const now = util.time.nowISO8601();
  expressionNames['#updatedAt'] = 'updatedAt';
  expressionNames['#version'] = 'version';
  expressionValues[':updatedAt'] = { S: now };
  expressionValues[':version'] = { N: '1' };
  expressionValues[':expectedVersion'] = { N: String(input.version || 1) };
  
  updateExpressions.push('#updatedAt = :updatedAt');
  updateExpressions.push('#version = #version + :version');

  // 📊 DynamoDB UpdateItem リクエスト
  return {
    operation: 'UpdateItem',
    key: {
      id: { S: input.id }
    },
    update: {
      expression: `SET ${updateExpressions.join(', ')}`,
      expressionNames,
      expressionValues
    },
    // 🔒 楽観的ロック（バージョンチェック）
    condition: {
      expression: '#version = :expectedVersion',
      expressionNames: {
        '#version': 'version'
      },
      expressionValues: {
        ':expectedVersion': expressionValues[':expectedVersion']
      }
    }
  };
}

export function response(ctx) {
  console.log('UpdateItem response:', JSON.stringify(ctx, null, 2));
  
  // 🚨 DynamoDBエラーハンドリング
  if (ctx.error) {
    console.error('DynamoDB UpdateItem error:', ctx.error);
    
    // 条件チェック失敗（バージョン不一致）
    if (ctx.error.type === 'ConditionalCheckFailedException') {
      throw new Error('アイテムが他のユーザーによって更新されています。最新情報を取得してから再試行してください。');
    }
    
    // アイテム未存在
    if (ctx.error.type === 'ResourceNotFoundException') {
      throw new Error('更新対象のアイテムが見つかりません');
    }
    
    throw new Error(`アイテムの更新に失敗しました: ${ctx.error.message}`);
  }

  // ✅ 更新されたアイテムを返す
  const { result } = ctx;
  return {
    id: result.id?.S,
    name: result.name?.S,
    description: result.description?.S,
    status: result.status?.S,
    userId: result.userId?.S,
    createdAt: result.createdAt?.S,
    updatedAt: result.updatedAt?.S,
    version: result.version?.N ? parseInt(result.version.N) : 1
  };
}
```

### 🗑️ アイテム削除（DeleteItem）

```javascript
/**
 * 🗑️ アイテム削除リゾルバー
 * DynamoDB DeleteItem オペレーション
 * 所有者チェック、ソフト削除オプション
 */

export function request(ctx) {
  console.log('DeleteItem request:', JSON.stringify(ctx, null, 2));
  
  // 🔒 認証チェック
  const { identity } = ctx;
  if (!identity || !identity.username) {
    throw new Error('認証が必要です');
  }

  // 📝 パラメータの検証
  const { id } = ctx.args;
  if (!id) {
    throw new Error('IDは必須パラメータです');
  }

  const username = identity.username;

  // 📊 DynamoDB DeleteItem リクエスト
  return {
    operation: 'DeleteItem',
    key: {
      id: { S: id }
    },
    // 🔒 所有者チェック条件
    condition: {
      expression: 'userId = :userId',
      expressionValues: {
        ':userId': { S: username }
      }
    }
  };
}

export function response(ctx) {
  console.log('DeleteItem response:', JSON.stringify(ctx, null, 2));
  
  // 🚨 DynamoDBエラーハンドリング
  if (ctx.error) {
    console.error('DynamoDB DeleteItem error:', ctx.error);
    
    // 条件チェック失敗（所有者不一致またはアイテム未存在）
    if (ctx.error.type === 'ConditionalCheckFailedException') {
      throw new Error('削除権限がないか、アイテムが見つかりません');
    }
    
    throw new Error(`アイテムの削除に失敗しました: ${ctx.error.message}`);
  }

  // ✅ 削除されたアイテム情報を返す
  const { result } = ctx;
  if (!result || Object.keys(result).length === 0) {
    throw new Error('削除対象のアイテムが見つかりません');
  }

  return {
    id: result.id?.S,
    name: result.name?.S,
    deletedAt: new Date().toISOString()
  };
}
```

## 🎯 使用方法

### 1. リゾルバーファイルの配置
```
resolvers/
├── Query_getEntity.js          # 単一エンティティ取得
├── Mutation_createEntity.js    # エンティティ作成
├── Mutation_updateEntity.js    # エンティティ更新
└── Mutation_deleteEntity.js    # エンティティ削除
```

### 2. Terraformでのリゾルバー設定例
```hcl
resource "aws_appsync_resolver" "get_entity" {
  api_id      = aws_appsync_graphql_api.api.id
  field       = "getEntity"
  type        = "Query"
  data_source = aws_appsync_datasource.dynamodb.name
  
  code = file("${path.module}/../resolvers/Query_getEntity.js")
  runtime {
    name            = "APPSYNC_JS"
    runtime_version = "1.0.0"
  }
}
```

### 3. 共通エラーハンドリング関数
```javascript
// utils/errorHandling.js
export function handleDynamoDBError(error, operation) {
  console.error(`DynamoDB ${operation} error:`, error);
  
  switch (error.type) {
    case 'ConditionalCheckFailedException':
      if (operation === 'UpdateItem') {
        throw new Error('データが他のユーザーによって更新されています');
      } else if (operation === 'DeleteItem') {
        throw new Error('削除権限がないか、データが見つかりません');
      } else {
        throw new Error('条件チェックに失敗しました');
      }
    
    case 'ResourceNotFoundException':
      throw new Error('指定されたデータが見つかりません');
    
    case 'ValidationException':
      throw new Error('入力データの形式が正しくありません');
    
    case 'ProvisionedThroughputExceededException':
      throw new Error('一時的にアクセスが集中しています。しばらく待ってから再試行してください');
    
    default:
      throw new Error(`データベース操作に失敗しました: ${error.message}`);
  }
}

export function validateRequired(value, fieldName) {
  if (!value || (typeof value === 'string' && value.trim().length === 0)) {
    throw new Error(`${fieldName}は必須です`);
  }
}

export function validateLength(value, fieldName, maxLength) {
  if (value && value.length > maxLength) {
    throw new Error(`${fieldName}は${maxLength}文字以内で入力してください`);
  }
}
```

## 🔗 関連テンプレート

- [JavaScript リゾルバー高度操作テンプレート](./javascript-resolver-advanced-template.md) - クエリとバッチ操作
- [JavaScript リゾルバーユーティリティテンプレート](./javascript-resolver-utils-template.md) - 共通関数とヘルパー

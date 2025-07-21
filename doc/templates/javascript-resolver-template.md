# 🧠 JavaScriptリゾルバーテンプレート

このファイルには、AWS AppSync用のJavaScriptリゾルバーテンプレートが含まれています。

## 📖 基本的なCRUD操作リゾルバー

### 🔍 単一アイテム取得（GetItem）

```javascript
/**
 * 🔍 単一エンティティ取得リゾルバー
 * IDを指定して特定のエンティティを取得します
 */

import { util } from '@aws-appsync/utils';

/**
 * リクエスト処理：DynamoDBへのGetItemリクエストを作成
 */
export function request(ctx) {
    console.log('GetEntity request:', JSON.stringify(ctx.args, null, 2));
    
    return {
        operation: 'GetItem',                    // DynamoDB操作タイプ
        key: util.dynamodb.toMapValues({        // 主キーの指定
            id: ctx.args.id                     // 引数から取得したID
        }),
        // 一貫した読み取り（強い整合性）が必要な場合
        consistentRead: true
    };
}

/**
 * レスポンス処理：DynamoDBの結果をGraphQLレスポンスに変換
 */
export function response(ctx) {
    console.log('GetEntity response:', JSON.stringify(ctx.result, null, 2));
    
    // エラーハンドリング
    if (ctx.error) {
        console.error('GetEntity error:', ctx.error);
        util.error(ctx.error.message, ctx.error.type);
    }

    // アイテムが見つからない場合はnullを返す
    if (!ctx.result) {
        return null;
    }

    // DynamoDBの結果をそのまま返す（AppSyncが自動で変換）
    return ctx.result;
}
```

### 📝 アイテム作成（PutItem）

```javascript
/**
 * 📝 エンティティ作成リゾルバー
 * 新しいエンティティをDynamoDBに保存します
 */

import { util } from '@aws-appsync/utils';

/**
 * リクエスト処理：作成データの準備とバリデーション
 */
export function request(ctx) {
    console.log('CreateEntity request:', JSON.stringify(ctx.args, null, 2));
    
    // 現在時刻を取得（ISO 8601形式）
    const now = util.time.nowISO8601();
    
    // 一意IDを生成（UUID v4形式）
    const entityId = util.autoId();
    
    // 入力データの検証
    const input = ctx.args.input;
    if (!input.name || input.name.trim() === '') {
        util.error('名前は必須です', 'ValidationError');
    }
    
    // 保存するアイテムデータを構築
    const item = {
        id: entityId,                           // 一意ID
        name: input.name.trim(),                // 名前（前後の空白を除去）
        description: input.description || '',   // 説明（デフォルト値設定）
        status: input.status || 'ACTIVE',       // ステータス（デフォルト値設定）
        userId: ctx.identity.sub,               // 認証されたユーザーID
        createdAt: now,                         // 作成日時
        updatedAt: now,                         // 更新日時
        version: 1                              // バージョン（楽観的ロック用）
    };

    return {
        operation: 'PutItem',                   // DynamoDB操作タイプ
        key: util.dynamodb.toMapValues({        // 主キー
            id: entityId
        }),
        attributeValues: util.dynamodb.toMapValues(item), // 保存データ
        
        // 条件：同じIDのアイテムが存在しない場合のみ作成
        condition: {
            expression: 'attribute_not_exists(id)'
        }
    };
}

/**
 * レスポンス処理：作成結果の確認とログ
 */
export function response(ctx) {
    console.log('CreateEntity response:', JSON.stringify(ctx.result, null, 2));
    
    // エラーハンドリング
    if (ctx.error) {
        console.error('CreateEntity error:', ctx.error);
        
        // 条件チェックエラー（重複）の場合
        if (ctx.error.type === 'ConditionalCheckFailedException') {
            util.error('同じIDのエンティティが既に存在します', 'DuplicationError');
        }
        
        util.error(ctx.error.message, ctx.error.type);
    }

    // 作成されたアイテムを返す
    return ctx.result;
}
```

### ✏️ アイテム更新（UpdateItem）

```javascript
/**
 * ✏️ エンティティ更新リゾルバー
 * 既存のエンティティを部分的に更新します
 */

import { util } from '@aws-appsync/utils';

/**
 * リクエスト処理：更新式の構築
 */
export function request(ctx) {
    console.log('UpdateEntity request:', JSON.stringify(ctx.args, null, 2));
    
    const input = ctx.args.input;
    const now = util.time.nowISO8601();
    
    // 更新式とパラメータを動的に構築
    const updateExpressions = [];
    const expressionNames = {};
    const expressionValues = {};
    
    // 名前の更新
    if (input.name !== undefined) {
        if (input.name.trim() === '') {
            util.error('名前は空にできません', 'ValidationError');
        }
        updateExpressions.push('#name = :name');
        expressionNames['#name'] = 'name';
        expressionValues[':name'] = input.name.trim();
    }
    
    // 説明の更新
    if (input.description !== undefined) {
        updateExpressions.push('#description = :description');
        expressionNames['#description'] = 'description';
        expressionValues[':description'] = input.description;
    }
    
    // ステータスの更新
    if (input.status !== undefined) {
        updateExpressions.push('#status = :status');
        expressionNames['#status'] = 'status';
        expressionValues[':status'] = input.status;
    }
    
    // 更新日時は常に更新
    updateExpressions.push('#updatedAt = :updatedAt');
    expressionNames['#updatedAt'] = 'updatedAt';
    expressionValues[':updatedAt'] = now;
    
    // バージョンを増加（楽観的ロック）
    updateExpressions.push('#version = #version + :versionIncrement');
    expressionNames['#version'] = 'version';
    expressionValues[':versionIncrement'] = 1;
    
    // 更新対象フィールドがない場合
    if (updateExpressions.length === 2) { // updatedAtとversionのみ
        util.error('更新対象のフィールドが指定されていません', 'ValidationError');
    }

    return {
        operation: 'UpdateItem',                // DynamoDB操作タイプ
        key: util.dynamodb.toMapValues({        // 主キー
            id: input.id
        }),
        update: {
            expression: 'SET ' + updateExpressions.join(', '),
            expressionNames: expressionNames,
            expressionValues: util.dynamodb.toMapValues(expressionValues)
        },
        
        // 条件：アイテムが存在し、バージョンが一致する場合のみ更新
        condition: {
            expression: 'attribute_exists(id) AND #version = :currentVersion',
            expressionNames: {
                '#version': 'version'
            },
            expressionValues: util.dynamodb.toMapValues({
                ':currentVersion': input.version || 1
            })
        }
    };
}

/**
 * レスポンス処理：更新結果の確認
 */
export function response(ctx) {
    console.log('UpdateEntity response:', JSON.stringify(ctx.result, null, 2));
    
    // エラーハンドリング
    if (ctx.error) {
        console.error('UpdateEntity error:', ctx.error);
        
        // 条件チェックエラー（存在しないまたはバージョン不一致）
        if (ctx.error.type === 'ConditionalCheckFailedException') {
            util.error('エンティティが存在しないか、他のユーザーによって更新されています', 'ConflictError');
        }
        
        util.error(ctx.error.message, ctx.error.type);
    }

    // 更新後の全属性を返す
    return ctx.result;
}
```

### 🗑️ アイテム削除（DeleteItem）

```javascript
/**
 * 🗑️ エンティティ削除リゾルバー
 * 指定されたエンティティを削除します
 */

import { util } from '@aws-appsync/utils';

/**
 * リクエスト処理：削除前の確認
 */
export function request(ctx) {
    console.log('DeleteEntity request:', JSON.stringify(ctx.args, null, 2));
    
    return {
        operation: 'DeleteItem',                // DynamoDB操作タイプ
        key: util.dynamodb.toMapValues({        // 主キー
            id: ctx.args.id
        }),
        
        // 条件：アイテムが存在し、削除権限がある場合のみ削除
        condition: {
            expression: 'attribute_exists(id) AND #userId = :userId',
            expressionNames: {
                '#userId': 'userId'
            },
            expressionValues: util.dynamodb.toMapValues({
                ':userId': ctx.identity.sub  // 認証されたユーザーのみ削除可能
            })
        }
    };
}

/**
 * レスポンス処理：削除結果の確認
 */
export function response(ctx) {
    console.log('DeleteEntity response:', JSON.stringify(ctx.result, null, 2));
    
    // エラーハンドリング
    if (ctx.error) {
        console.error('DeleteEntity error:', ctx.error);
        
        // 条件チェックエラー（存在しないまたは権限なし）
        if (ctx.error.type === 'ConditionalCheckFailedException') {
            util.error('エンティティが存在しないか、削除権限がありません', 'ForbiddenError');
        }
        
        util.error(ctx.error.message, ctx.error.type);
    }

    // 削除されたアイテムの情報を返す
    return ctx.result;
}
```

## 📋 クエリ操作リゾルバー

### 🔍 リスト取得（Query）

```javascript
/**
 * 📋 エンティティ一覧取得リゾルバー
 * 条件に基づいてエンティティ一覧を取得します
 */

import { util } from '@aws-appsync/utils';

/**
 * リクエスト処理：クエリ条件の構築
 */
export function request(ctx) {
    console.log('ListEntities request:', JSON.stringify(ctx.args, null, 2));
    
    const args = ctx.args;
    
    // ユーザー別検索
    if (args.userId) {
        return {
            operation: 'Query',                 // DynamoDB操作タイプ
            index: 'UserIdIndex',               // グローバルセカンダリインデックス
            query: {
                expression: '#userId = :userId',
                expressionNames: {
                    '#userId': 'userId'
                },
                expressionValues: util.dynamodb.toMapValues({
                    ':userId': args.userId
                })
            },
            // ソート順序（新しい順）
            scanIndexForward: false,
            
            // ページング
            limit: args.limit || 20,
            nextToken: args.nextToken
        };
    }
    
    // ステータス別検索
    if (args.status) {
        return {
            operation: 'Query',
            index: 'StatusIndex',
            query: {
                expression: '#status = :status',
                expressionNames: {
                    '#status': 'status'
                },
                expressionValues: util.dynamodb.toMapValues({
                    ':status': args.status
                })
            },
            scanIndexForward: false,
            limit: args.limit || 20,
            nextToken: args.nextToken
        };
    }
    
    // 全件取得（Scan）- 大量データの場合は注意
    return {
        operation: 'Scan',                      // 全テーブルスキャン
        limit: args.limit || 20,
        nextToken: args.nextToken,
        
        // フィルタ条件（必要に応じて）
        filter: args.filter ? {
            expression: '#status = :activeStatus',
            expressionNames: {
                '#status': 'status'
            },
            expressionValues: util.dynamodb.toMapValues({
                ':activeStatus': 'ACTIVE'
            })
        } : undefined
    };
}

/**
 * レスポンス処理：結果の整形
 */
export function response(ctx) {
    console.log('ListEntities response:', JSON.stringify(ctx.result, null, 2));
    
    // エラーハンドリング
    if (ctx.error) {
        console.error('ListEntities error:', ctx.error);
        util.error(ctx.error.message, ctx.error.type);
    }

    // ページング情報付きで返す
    return {
        items: ctx.result.items || [],          // 取得したアイテム一覧
        nextToken: ctx.result.nextToken,        // 次ページのトークン
        scannedCount: ctx.result.scannedCount,  // スキャンしたアイテム数
        count: ctx.result.count                 // 実際に返されたアイテム数
    };
}
```

### 🔍 検索クエリ（FilterExpression）

```javascript
/**
 * 🔍 エンティティ検索リゾルバー
 * キーワードに基づいてエンティティを検索します
 */

import { util } from '@aws-appsync/utils';

/**
 * リクエスト処理：検索条件の構築
 */
export function request(ctx) {
    console.log('SearchEntities request:', JSON.stringify(ctx.args, null, 2));
    
    const keyword = ctx.args.keyword;
    
    // キーワードが空の場合はエラー
    if (!keyword || keyword.trim() === '') {
        util.error('検索キーワードが指定されていません', 'ValidationError');
    }

    return {
        operation: 'Scan',                      // 全体検索のためScanを使用
        filter: {
            expression: 'contains(#name, :keyword) OR contains(#description, :keyword)',
            expressionNames: {
                '#name': 'name',
                '#description': 'description'
            },
            expressionValues: util.dynamodb.toMapValues({
                ':keyword': keyword.trim()
            })
        },
        limit: ctx.args.limit || 10             // 検索結果は少なめに制限
    };
}

/**
 * レスポンス処理：検索結果の整形
 */
export function response(ctx) {
    console.log('SearchEntities response:', JSON.stringify(ctx.result, null, 2));
    
    // エラーハンドリング
    if (ctx.error) {
        console.error('SearchEntities error:', ctx.error);
        util.error(ctx.error.message, ctx.error.type);
    }

    // 検索結果をスコア順にソート（より関連性の高いものを上位に）
    const items = ctx.result.items || [];
    const keyword = ctx.args.keyword.toLowerCase();
    
    const scoredItems = items.map(item => {
        let score = 0;
        
        // 名前に完全一致があれば高スコア
        if (item.name.toLowerCase() === keyword) {
            score += 100;
        }
        // 名前に部分一致があればスコア追加
        else if (item.name.toLowerCase().includes(keyword)) {
            score += 50;
        }
        
        // 説明に部分一致があればスコア追加
        if (item.description && item.description.toLowerCase().includes(keyword)) {
            score += 25;
        }
        
        return { ...item, _score: score };
    });
    
    // スコア順でソート
    scoredItems.sort((a, b) => b._score - a._score);
    
    // スコア情報を除去して返す
    const finalItems = scoredItems.map(item => {
        const { _score, ...itemWithoutScore } = item;
        return itemWithoutScore;
    });

    return finalItems;
}
```

## 🔔 Subscription リゾルバー

### 📢 リアルタイム通知

```javascript
/**
 * 🔔 リアルタイム通知リゾルバー（Subscription）
 * エンティティの作成イベントを配信します
 */

import { util } from '@aws-appsync/utils';

/**
 * リクエスト処理：通知の配信条件を設定
 */
export function request(ctx) {
    console.log('OnEntityCreated request:', JSON.stringify(ctx.args, null, 2));
    
    // Subscriptionでは通常、フィルタリング情報のみ設定
    return {
        // フィルタ条件（特定ユーザーの作成イベントのみ通知）
        filter: ctx.args.userId ? {
            userId: ctx.args.userId
        } : null
    };
}

/**
 * レスポンス処理：通知データの整形
 */
export function response(ctx) {
    console.log('OnEntityCreated response:', JSON.stringify(ctx.result, null, 2));
    
    // エラーハンドリング
    if (ctx.error) {
        console.error('OnEntityCreated error:', ctx.error);
        util.error(ctx.error.message, ctx.error.type);
    }

    // ミューテーションからの結果をそのまま配信
    return ctx.result;
}
```

## 🔗 関連データ取得リゾルバー

### 🔗 関連エンティティ取得

```javascript
/**
 * 🔗 関連エンティティ取得リゾルバー
 * メインエンティティに関連するデータを取得します
 */

import { util } from '@aws-appsync/utils';

/**
 * リクエスト処理：関連データの取得クエリ
 */
export function request(ctx) {
    console.log('GetRelatedEntities request:', JSON.stringify(ctx.source, null, 2));
    
    // 親エンティティ（source）からIDを取得
    const parentId = ctx.source.id;
    
    return {
        operation: 'Query',
        index: 'ParentIdIndex',                 // 親ID用のインデックス
        query: {
            expression: '#parentId = :parentId',
            expressionNames: {
                '#parentId': 'parentId'
            },
            expressionValues: util.dynamodb.toMapValues({
                ':parentId': parentId
            })
        },
        // 関連エンティティは最新順で取得
        scanIndexForward: false,
        limit: 100                              // 関連データの上限
    };
}

/**
 * レスポンス処理：関連データの返却
 */
export function response(ctx) {
    console.log('GetRelatedEntities response:', JSON.stringify(ctx.result, null, 2));
    
    // エラーハンドリング
    if (ctx.error) {
        console.error('GetRelatedEntities error:', ctx.error);
        util.error(ctx.error.message, ctx.error.type);
    }

    // 関連エンティティの配列を返す
    return ctx.result.items || [];
}
```

## 📊 統計データリゾルバー

### 📊 集計クエリ

```javascript
/**
 * 📊 統計データ取得リゾルバー
 * エンティティの統計情報を計算します
 */

import { util } from '@aws-appsync/utils';

/**
 * リクエスト処理：統計用データの取得
 */
export function request(ctx) {
    console.log('GetEntityStats request:', JSON.stringify(ctx.args, null, 2));
    
    const userId = ctx.args.userId;
    
    if (userId) {
        // 特定ユーザーの統計
        return {
            operation: 'Query',
            index: 'UserIdIndex',
            query: {
                expression: '#userId = :userId',
                expressionNames: {
                    '#userId': 'userId'
                },
                expressionValues: util.dynamodb.toMapValues({
                    ':userId': userId
                })
            }
        };
    } else {
        // 全体統計
        return {
            operation: 'Scan'
        };
    }
}

/**
 * レスポンス処理：統計の計算
 */
export function response(ctx) {
    console.log('GetEntityStats response items count:', ctx.result.items?.length);
    
    // エラーハンドリング
    if (ctx.error) {
        console.error('GetEntityStats error:', ctx.error);
        util.error(ctx.error.message, ctx.error.type);
    }

    const items = ctx.result.items || [];
    const now = new Date();
    const today = now.toISOString().split('T')[0]; // YYYY-MM-DD形式
    
    // 統計計算
    const stats = {
        total: items.length,
        activeCount: 0,
        inactiveCount: 0,
        todayCreated: 0,
        recentItems: []
    };
    
    // 各アイテムを分析
    items.forEach(item => {
        // ステータス別カウント
        if (item.status === 'ACTIVE') {
            stats.activeCount++;
        } else {
            stats.inactiveCount++;
        }
        
        // 今日作成されたアイテムのカウント
        if (item.createdAt && item.createdAt.startsWith(today)) {
            stats.todayCreated++;
        }
    });
    
    // 最近のアイテム（最大5件）
    stats.recentItems = items
        .sort((a, b) => (b.createdAt || '').localeCompare(a.createdAt || ''))
        .slice(0, 5);
    
    console.log('Calculated stats:', JSON.stringify(stats, null, 2));
    return stats;
}
```

## 🛠 エラーハンドリングのベストプラクティス

### 共通エラーハンドリング関数

```javascript
/**
 * 🛠 共通エラーハンドリング関数
 * リゾルバー間で共通して使用するエラー処理
 */

import { util } from '@aws-appsync/utils';

/**
 * エラータイプ別の処理
 */
export function handleCommonErrors(error, operation = 'unknown') {
    console.error(`${operation} error:`, JSON.stringify(error, null, 2));
    
    switch (error.type) {
        case 'ConditionalCheckFailedException':
            if (operation.includes('Create')) {
                util.error('指定されたリソースは既に存在します', 'DuplicationError');
            } else if (operation.includes('Update')) {
                util.error('リソースが存在しないか、他のユーザーによって更新されています', 'ConflictError');
            } else if (operation.includes('Delete')) {
                util.error('リソースが存在しないか、削除権限がありません', 'ForbiddenError');
            }
            break;
            
        case 'ValidationException':
            util.error('入力データの形式が正しくありません', 'ValidationError');
            break;
            
        case 'ResourceNotFoundException':
            util.error('指定されたリソースが見つかりません', 'NotFoundError');
            break;
            
        case 'ProvisionedThroughputExceededException':
            util.error('リクエストが多すぎます。しばらく待ってから再度お試しください', 'ThrottleError');
            break;
            
        case 'ServiceUnavailableException':
            util.error('サービスが一時的に利用できません。しばらく待ってから再度お試しください', 'ServiceError');
            break;
            
        default:
            util.error(`操作中にエラーが発生しました: ${error.message}`, error.type || 'UnknownError');
    }
}

/**
 * 入力バリデーション
 */
export function validateInput(input, requiredFields = []) {
    const errors = [];
    
    // 必須フィールドのチェック
    requiredFields.forEach(field => {
        if (!input[field] || (typeof input[field] === 'string' && input[field].trim() === '')) {
            errors.push(`${field}は必須です`);
        }
    });
    
    // 文字列長のチェック
    if (input.name && input.name.length > 100) {
        errors.push('名前は100文字以内で入力してください');
    }
    
    if (input.description && input.description.length > 1000) {
        errors.push('説明は1000文字以内で入力してください');
    }
    
    // エラーがある場合は例外を投げる
    if (errors.length > 0) {
        util.error(errors.join(', '), 'ValidationError');
    }
}
```

---

**💡 これらのテンプレートを組み合わせて、robust なリゾルバーを効率的に実装できます！**

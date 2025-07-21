# 🧠 JavaScript リゾルバー高度操作テンプレート

このファイルには、AWS AppSyncで使用する高度なクエリ操作、検索、統計、関連データ取得のJavaScriptリゾルバーテンプレートが含まれています。

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
        throw new Error(`エンティティ一覧の取得に失敗しました: ${ctx.error.message}`);
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
        throw new Error('検索キーワードが指定されていません');
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
        throw new Error(`検索に失敗しました: ${ctx.error.message}`);
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
    
    if (!parentId) {
        throw new Error('親エンティティのIDが指定されていません');
    }
    
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
        throw new Error(`関連データの取得に失敗しました: ${ctx.error.message}`);
    }

    // 関連エンティティの配列を返す
    return ctx.result.items || [];
}
```

### 🔗 バッチ取得リゾルバー

```javascript
/**
 * 🔗 バッチ取得リゾルバー
 * 複数のIDを使って一括でエンティティを取得します
 */

import { util } from '@aws-appsync/utils';

/**
 * リクエスト処理：バッチ取得クエリ
 */
export function request(ctx) {
    console.log('BatchGetEntities request:', JSON.stringify(ctx.args, null, 2));
    
    const { ids } = ctx.args;
    
    if (!ids || ids.length === 0) {
        throw new Error('取得するIDが指定されていません');
    }

    if (ids.length > 100) {
        throw new Error('一度に取得できるアイテム数は100個までです');
    }

    // DynamoDB BatchGetItem リクエスト
    return {
        operation: 'BatchGetItem',
        tables: {
            'YourTableName': {               // テーブル名を適切に設定
                keys: ids.map(id => ({
                    id: { S: id }
                }))
            }
        }
    };
}

/**
 * レスポンス処理：バッチ取得結果の返却
 */
export function response(ctx) {
    console.log('BatchGetEntities response:', JSON.stringify(ctx.result, null, 2));
    
    // エラーハンドリング
    if (ctx.error) {
        console.error('BatchGetEntities error:', ctx.error);
        throw new Error(`バッチ取得に失敗しました: ${ctx.error.message}`);
    }

    // テーブル別の結果を統合
    const items = ctx.result.data?.YourTableName || [];
    
    // 型変換を行って返す
    return items.map(item => ({
        id: item.id?.S,
        name: item.name?.S,
        description: item.description?.S,
        status: item.status?.S,
        userId: item.userId?.S,
        createdAt: item.createdAt?.S,
        updatedAt: item.updatedAt?.S,
        version: item.version?.N ? parseInt(item.version.N) : 1
    }));
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
 * リクエスト処理：統計データ取得のためのクエリ
 */
export function request(ctx) {
    console.log('GetEntityStats request:', JSON.stringify(ctx.args, null, 2));
    
    const { userId } = ctx.args;
    
    // ユーザー指定がある場合はユーザー別統計
    if (userId) {
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
            },
            // 統計用なのでプロジェクションで必要な属性のみ取得
            select: 'SPECIFIC_ATTRIBUTES',
            projectionExpression: '#status, #createdAt, #name',
            expressionNames: {
                '#status': 'status',
                '#createdAt': 'createdAt',
                '#name': 'name'
            }
        };
    }
    
    // 全体統計の場合はScan
    return {
        operation: 'Scan',
        select: 'SPECIFIC_ATTRIBUTES',
        projectionExpression: '#status, #createdAt, #name',
        expressionNames: {
            '#status': 'status',
            '#createdAt': 'createdAt',
            '#name': 'name'
        }
    };
}

/**
 * レスポンス処理：統計データの計算と返却
 */
export function response(ctx) {
    console.log('GetEntityStats response:', JSON.stringify(ctx.result, null, 2));
    
    // エラーハンドリング
    if (ctx.error) {
        console.error('GetEntityStats error:', ctx.error);
        throw new Error(`統計データの取得に失敗しました: ${ctx.error.message}`);
    }

    const items = ctx.result.items || [];
    
    // 統計計算
    const stats = {
        total: items.length,
        activeCount: 0,
        inactiveCount: 0,
        archivedCount: 0,
        todayCreated: 0,
        recentItems: []
    };
    
    const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD
    
    items.forEach(item => {
        // ステータス別カウント
        switch (item.status) {
            case 'ACTIVE':
                stats.activeCount++;
                break;
            case 'INACTIVE':
                stats.inactiveCount++;
                break;
            case 'ARCHIVED':
                stats.archivedCount++;
                break;
        }
        
        // 今日作成されたアイテムをカウント
        if (item.createdAt && item.createdAt.startsWith(today)) {
            stats.todayCreated++;
        }
    });
    
    // 最近作成されたアイテム（上位5件）
    const sortedItems = [...items]
        .sort((a, b) => (b.createdAt || '').localeCompare(a.createdAt || ''))
        .slice(0, 5);
    
    stats.recentItems = sortedItems.map(item => ({
        id: item.id,
        name: item.name,
        createdAt: item.createdAt
    }));
    
    return stats;
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
        throw new Error(`通知の配信に失敗しました: ${ctx.error.message}`);
    }

    // ミューテーションからの結果をそのまま配信
    return ctx.result;
}
```

### 🔔 条件付きサブスクリプション

```javascript
/**
 * 🔔 条件付きサブスクリプション
 * 特定の条件を満たすエンティティの更新のみ通知
 */

export function request(ctx) {
    console.log('OnEntityStatusChanged request:', JSON.stringify(ctx.args, null, 2));
    
    const { entityId, status } = ctx.args;
    
    return {
        // 複数条件でのフィルタリング
        filter: {
            ...(entityId && { id: entityId }),
            ...(status && { status: status })
        }
    };
}

export function response(ctx) {
    console.log('OnEntityStatusChanged response:', JSON.stringify(ctx.result, null, 2));
    
    if (ctx.error) {
        console.error('OnEntityStatusChanged error:', ctx.error);
        throw new Error(`ステータス変更通知の配信に失敗しました: ${ctx.error.message}`);
    }

    // 特定のフィールドのみ通知
    return {
        id: ctx.result.id,
        status: ctx.result.status,
        updatedAt: ctx.result.updatedAt,
        version: ctx.result.version
    };
}
```

## 🎯 使用方法

### 1. パイプラインリゾルバーとの組み合わせ

```javascript
/**
 * パイプラインリゾルバーの第1段階：データ取得
 */
export function request(ctx) {
    const { source, args } = ctx;
    
    // 第1段階：メインデータを取得
    return {
        operation: 'GetItem',
        key: { id: { S: args.id } }
    };
}

export function response(ctx) {
    // 次の段階に渡すデータを準備
    if (!ctx.result || Object.keys(ctx.result).length === 0) {
        throw new Error('エンティティが見つかりません');
    }
    
    // 次の段階で使用するためにstashに保存
    ctx.stash.mainEntity = ctx.result;
    
    return ctx.result;
}
```

### 2. 条件分岐クエリ

```javascript
/**
 * 動的な条件分岐クエリリゾルバー
 */
export function request(ctx) {
    const { args } = ctx;
    
    // 条件に応じて異なるクエリパターンを使用
    if (args.searchType === 'byUser') {
        return {
            operation: 'Query',
            index: 'UserIdIndex',
            query: {
                expression: '#userId = :userId',
                expressionNames: { '#userId': 'userId' },
                expressionValues: util.dynamodb.toMapValues({ ':userId': args.userId })
            }
        };
    } else if (args.searchType === 'byDate') {
        return {
            operation: 'Query',
            index: 'DateIndex',
            query: {
                expression: '#date BETWEEN :startDate AND :endDate',
                expressionNames: { '#date': 'createdAt' },
                expressionValues: util.dynamodb.toMapValues({
                    ':startDate': args.startDate,
                    ':endDate': args.endDate
                })
            }
        };
    } else {
        throw new Error('サポートされていない検索タイプです');
    }
}
```

## 🔗 関連テンプレート

- [JavaScript リゾルバー基本操作テンプレート](./javascript-resolver-basic-template.md) - CRUD操作の実装
- [JavaScript リゾルバーユーティリティテンプレート](./javascript-resolver-utils-template.md) - 共通関数とヘルパー

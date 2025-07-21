# ⚛️ React フロントエンドテンプレート

このファイルには、AWS AppSync と連携するReactコンポーネントのテンプレートが含まれています。
**AWS Amplify v6** の `generateClient` を使用した実装例です。

## 📡 GraphQL操作定義テンプレート

### クエリテンプレート（src/graphql/queries.js）

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

### ミューテーションテンプレート（src/graphql/mutations.js）

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

### サブスクリプションテンプレート（src/graphql/subscriptions.js）

```javascript
/**
 * 🔔 GraphQLサブスクリプション定義
 * リアルタイム通知用のサブスクリプションを定義します
 * AWS Amplify v6 の generateClient で使用
 */

// 🆕 エンティティ作成通知
export const onEntityCreated = /* GraphQL */ `
  subscription OnEntityCreated($userId: String) {
    onEntityCreated(userId: $userId) {
      id                    # 新しく作成されたエンティティのID
      name                  # 名前
      description           # 説明
      status                # ステータス
      userId                # 作成者ID
      createdAt             # 作成日時
    }
  }
`;

// ✏️ エンティティ更新通知
export const onEntityUpdated = /* GraphQL */ `
  subscription OnEntityUpdated($entityId: ID) {
    onEntityUpdated(entityId: $entityId) {
      id                    # 更新されたエンティティのID
      name                  # 新しい名前
      description           # 新しい説明
      status                # 新しいステータス
      updatedAt             # 更新日時
      version               # 新しいバージョン
    }
  }
`;

// 🗑️ エンティティ削除通知
export const onEntityDeleted = /* GraphQL */ `
  subscription OnEntityDeleted($userId: String) {
    onEntityDeleted(userId: $userId) {
      id                    # 削除されたエンティティのID
      name                  # 削除されたエンティティの名前
      userId                # 元の所有者ID
    }
  }
`;

// 🔄 ステータス変更通知
export const onEntityStatusChanged = /* GraphQL */ `
  subscription OnEntityStatusChanged($entityId: ID) {
    onEntityStatusChanged(entityId: $entityId) {
      id                    # エンティティID
      name                  # 名前
      status                # 新しいステータス
      updatedAt             # 更新日時
    }
  }
`;

// 👤 ユーザー固有の変更通知
export const onUserEntityChanged = /* GraphQL */ `
  subscription OnUserEntityChanged($userId: String!) {
    onUserEntityChanged(userId: $userId) {
      id                    # 変更されたエンティティのID
      name                  # 名前
      status                # ステータス
      updatedAt             # 更新日時
      # 変更の種類は mutation 名から判断
    }
  }
`;
```

## 🧩 Reactコンポーネントテンプレート

### エンティティ一覧コンポーネント

```javascript
/**
 * 📋 エンティティ一覧コンポーネント
 * エンティティの一覧表示と基本的な操作を提供します
 * AWS Amplify v6 generateClient 使用
 */

import React, { useState, useEffect } from 'react';
import { generateClient } from 'aws-amplify/api';
import { 
  listEntities, 
  listEntitiesByUser,
  getEntityStats 
} from '../graphql/queries';
import { 
  deleteEntity, 
  activateEntity, 
  deactivateEntity 
} from '../graphql/mutations';
import { 
  onEntityCreated, 
  onEntityUpdated, 
  onEntityDeleted 
} from '../graphql/subscriptions';
import EntityCard from './EntityCard';
import LoadingSpinner from './LoadingSpinner';
import ErrorMessage from './ErrorMessage';

const client = generateClient();

function EntityList({ userId, showOnlyUserEntities = false, currentUser }) {
  // 🔹 状態管理
  const [entities, setEntities] = useState([]);
  const [filter, setFilter] = useState('ALL'); // ALL, ACTIVE, INACTIVE
  const [searchKeyword, setSearchKeyword] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);
  const [stats, setStats] = useState(null);

  // 🔹 エンティティ一覧の取得
  const fetchEntities = async () => {
    try {
      setIsLoading(true);
      const variables = {
        ...(showOnlyUserEntities && { userId }),
        ...(filter !== 'ALL' && { status: filter }),
        limit: 20
      };

      const result = await client.graphql({
        query: showOnlyUserEntities ? listEntitiesByUser : listEntities,
        variables
      });

      const items = showOnlyUserEntities 
        ? result.data.listEntitiesByUser 
        : result.data.listEntities;
      
      setEntities(Array.isArray(items) ? items : []);
    } catch (error) {
      console.error('エンティティ取得エラー:', error);
      setError('エンティティの取得に失敗しました');
    } finally {
      setIsLoading(false);
    }
  };

  // 🔹 統計データの取得
  const fetchStats = async () => {
    try {
      const variables = showOnlyUserEntities ? { userId } : {};
      const result = await client.graphql({
        query: getEntityStats,
        variables
      });
      setStats(result.data.getEntityStats);
    } catch (error) {
      console.error('統計データ取得エラー:', error);
    }
  };

  // 🔹 初期データ読み込み
  useEffect(() => {
    fetchEntities();
    fetchStats();
  }, [userId, showOnlyUserEntities, filter]);

  // 🔹 リアルタイム通知の設定
  useEffect(() => {
    const subscriptions = [];

    // 作成通知
    const createSubscription = client.graphql({
      query: onEntityCreated,
      variables: showOnlyUserEntities ? { userId } : {}
    }).subscribe({
      next: ({ data }) => {
        console.log('新しいエンティティが作成されました:', data);
        const newEntity = data.onEntityCreated;
        setEntities(prev => [newEntity, ...prev]);
      },
      error: (error) => console.error('作成通知エラー:', error)
    });

    // 更新通知
    const updateSubscription = client.graphql({
      query: onEntityUpdated
    }).subscribe({
      next: ({ data }) => {
        console.log('エンティティが更新されました:', data);
        const updatedEntity = data.onEntityUpdated;
        setEntities(prev => 
          prev.map(entity => 
            entity.id === updatedEntity.id ? { ...entity, ...updatedEntity } : entity
          )
        );
      },
      error: (error) => console.error('更新通知エラー:', error)
    });

    // 削除通知
    const deleteSubscription = client.graphql({
      query: onEntityDeleted,
      variables: showOnlyUserEntities ? { userId } : {}
    }).subscribe({
      next: ({ data }) => {
        console.log('エンティティが削除されました:', data);
        const deletedEntity = data.onEntityDeleted;
        setEntities(prev => prev.filter(entity => entity.id !== deletedEntity.id));
      },
      error: (error) => console.error('削除通知エラー:', error)
    });

    subscriptions.push(createSubscription, updateSubscription, deleteSubscription);

    // クリーンアップ
    return () => {
      subscriptions.forEach(subscription => subscription.unsubscribe());
    };
  }, [userId, showOnlyUserEntities]);

  // 🔹 フィルタリング処理
  const filteredEntities = entities.filter(entity => {
    if (searchKeyword) {
      const keyword = searchKeyword.toLowerCase();
      return entity.name.toLowerCase().includes(keyword) ||
             (entity.description && entity.description.toLowerCase().includes(keyword));
    }
    return true;
  });

  // 🔹 イベントハンドラー
  const handleDelete = async (entityId) => {
    if (window.confirm('このエンティティを削除しますか？')) {
      try {
        await client.graphql({
          query: deleteEntity,
          variables: { id: entityId }
        });
        // リアルタイム通知で自動更新される
      } catch (error) {
        console.error('削除処理でエラー:', error);
        setError('エンティティの削除に失敗しました');
      }
    }
  };

  const handleStatusToggle = async (entity) => {
    try {
      const mutation = entity.status === 'ACTIVE' ? deactivateEntity : activateEntity;
      await client.graphql({
        query: mutation,
        variables: { id: entity.id }
      });
      // リアルタイム通知で自動更新される
    } catch (error) {
      console.error('ステータス変更でエラー:', error);
      setError('ステータスの変更に失敗しました');
    }
  };

  // 🔹 レンダリング
  if (isLoading) {
    return <LoadingSpinner message="エンティティを読み込み中..." />;
  }

  if (error) {
    return (
      <ErrorMessage 
        message={error} 
        onRetry={() => {
          setError(null);
          fetchEntities();
        }}
      />
    );
  }

  return (
    <div className="entity-list">
      {/* 📊 統計情報 */}
      {stats && (
        <div className="stats-section">
          <h3>📊 統計情報</h3>
          <div className="stats-grid">
            <div className="stat-item">
              <span className="stat-number">{stats.total}</span>
              <span className="stat-label">総数</span>
            </div>
            <div className="stat-item">
              <span className="stat-number">{stats.activeCount}</span>
              <span className="stat-label">アクティブ</span>
            </div>
            <div className="stat-item">
              <span className="stat-number">{stats.inactiveCount}</span>
              <span className="stat-label">非アクティブ</span>
            </div>
            <div className="stat-item">
              <span className="stat-number">{stats.todayCreated}</span>
              <span className="stat-label">今日作成</span>
            </div>
          </div>
        </div>
      )}

      {/* 🔍 検索・フィルター */}
      <div className="controls-section">
        <div className="search-box">
          <input
            type="text"
            placeholder="エンティティを検索..."
            value={searchKeyword}
            onChange={(e) => setSearchKeyword(e.target.value)}
            className="search-input"
          />
        </div>
        
        <div className="filter-buttons">
          <button 
            className={filter === 'ALL' ? 'active' : ''}
            onClick={() => setFilter('ALL')}
          >
            すべて
          </button>
          <button 
            className={filter === 'ACTIVE' ? 'active' : ''}
            onClick={() => setFilter('ACTIVE')}
          >
            アクティブ
          </button>
          <button 
            className={filter === 'INACTIVE' ? 'active' : ''}
            onClick={() => setFilter('INACTIVE')}
          >
            非アクティブ
          </button>
        </div>
      </div>

      {/* 📋 エンティティ一覧 */}
      <div className="entities-grid">
        {filteredEntities.length > 0 ? (
          filteredEntities.map(entity => (
            <EntityCard
              key={entity.id}
              entity={entity}
              currentUser={currentUser}
              onDelete={() => handleDelete(entity.id)}
              onStatusToggle={() => handleStatusToggle(entity)}
              canEdit={entity.userId === currentUser?.sub}
              canDelete={entity.userId === currentUser?.sub}
            />
          ))
        ) : (
          <div className="empty-state">
            <p>エンティティが見つかりません</p>
            {searchKeyword && (
              <p>検索キーワード「{searchKeyword}」に一致するエンティティはありません</p>
            )}
          </div>
        )}
      </div>
    </div>
  );
}

export default EntityList;
```

### エンティティカードコンポーネント

```javascript
/**
 * 🎴 エンティティカードコンポーネント
 * 個別のエンティティを表示するカードUIコンポーネント
 */

import React, { useState } from 'react';
import { formatDistanceToNow } from 'date-fns';
import { ja } from 'date-fns/locale';

function EntityCard({ 
  entity, 
  currentUser, 
  onDelete, 
  onStatusToggle, 
  onEdit,
  canEdit = false, 
  canDelete = false 
}) {
  const [isExpanded, setIsExpanded] = useState(false);
  const [isActionMenuOpen, setIsActionMenuOpen] = useState(false);

  // 🔹 日時のフォーマット
  const formatDate = (dateString) => {
    if (!dateString) return '';
    
    try {
      return formatDistanceToNow(new Date(dateString), {
        addSuffix: true,
        locale: ja
      });
    } catch (error) {
      console.error('日付フォーマットエラー:', error);
      return dateString;
    }
  };

  // 🔹 ステータスの表示用設定
  const getStatusConfig = (status) => {
    switch (status) {
      case 'ACTIVE':
        return { label: 'アクティブ', className: 'status-active', emoji: '✅' };
      case 'INACTIVE':
        return { label: '非アクティブ', className: 'status-inactive', emoji: '⏸️' };
      case 'PENDING':
        return { label: '保留中', className: 'status-pending', emoji: '⏳' };
      case 'DELETED':
        return { label: '削除済み', className: 'status-deleted', emoji: '🗑️' };
      default:
        return { label: status, className: 'status-unknown', emoji: '❓' };
    }
  };

  const statusConfig = getStatusConfig(entity.status);

  // 🔹 イベントハンドラー
  const handleCardClick = () => {
    setIsExpanded(!isExpanded);
  };

  const handleActionClick = (e, action) => {
    e.stopPropagation(); // カードクリックイベントを停止
    setIsActionMenuOpen(false);
    
    switch (action) {
      case 'edit':
        onEdit && onEdit(entity);
        break;
      case 'delete':
        onDelete && onDelete(entity.id);
        break;
      case 'toggleStatus':
        onStatusToggle && onStatusToggle(entity);
        break;
      default:
        break;
    }
  };

  // 🔹 説明文の短縮表示
  const truncateDescription = (text, maxLength = 100) => {
    if (!text) return '';
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength) + '...';
  };

  return (
    <div className={`entity-card ${isExpanded ? 'expanded' : ''}`}>
      {/* 📄 カードヘッダー */}
      <div className="card-header" onClick={handleCardClick}>
        <div className="card-title-section">
          <h3 className="entity-name">{entity.name}</h3>
          <div className={`status-badge ${statusConfig.className}`}>
            <span className="status-emoji">{statusConfig.emoji}</span>
            <span className="status-label">{statusConfig.label}</span>
          </div>
        </div>
        
        {/* アクションメニュー */}
        {(canEdit || canDelete) && (
          <div className="action-menu">
            <button 
              className="action-menu-trigger"
              onClick={(e) => {
                e.stopPropagation();
                setIsActionMenuOpen(!isActionMenuOpen);
              }}
            >
              ⋮
            </button>
            
            {isActionMenuOpen && (
              <div className="action-menu-dropdown">
                {canEdit && (
                  <>
                    <button 
                      onClick={(e) => handleActionClick(e, 'edit')}
                      className="action-item"
                    >
                      ✏️ 編集
                    </button>
                    <button 
                      onClick={(e) => handleActionClick(e, 'toggleStatus')}
                      className="action-item"
                    >
                      {entity.status === 'ACTIVE' ? '⏸️ 無効化' : '▶️ 有効化'}
                    </button>
                  </>
                )}
                {canDelete && (
                  <button 
                    onClick={(e) => handleActionClick(e, 'delete')}
                    className="action-item danger"
                  >
                    🗑️ 削除
                  </button>
                )}
              </div>
            )}
          </div>
        )}
      </div>

      {/* 📝 カード本文 */}
      <div className="card-body">
        {/* 説明文 */}
        {entity.description && (
          <p className="entity-description">
            {isExpanded 
              ? entity.description 
              : truncateDescription(entity.description)
            }
          </p>
        )}

        {/* 展開時の詳細情報 */}
        {isExpanded && (
          <div className="entity-details">
            <div className="detail-item">
              <span className="detail-label">ID:</span>
              <span className="detail-value">{entity.id}</span>
            </div>
            
            {entity.userId && (
              <div className="detail-item">
                <span className="detail-label">作成者:</span>
                <span className="detail-value">{entity.userId}</span>
              </div>
            )}
            
            {entity.version && (
              <div className="detail-item">
                <span className="detail-label">バージョン:</span>
                <span className="detail-value">{entity.version}</span>
              </div>
            )}

            {entity.itemCount !== undefined && (
              <div className="detail-item">
                <span className="detail-label">関連アイテム数:</span>
                <span className="detail-value">{entity.itemCount}</span>
              </div>
            )}
          </div>
        )}

        {/* タイムスタンプ */}
        <div className="card-footer">
          <div className="timestamps">
            {entity.createdAt && (
              <span className="timestamp">
                📅 作成: {formatDate(entity.createdAt)}
              </span>
            )}
            {entity.updatedAt && entity.updatedAt !== entity.createdAt && (
              <span className="timestamp">
                ✏️ 更新: {formatDate(entity.updatedAt)}
              </span>
            )}
          </div>
          
          {/* 展開ボタン */}
          <button className="expand-button" onClick={handleCardClick}>
            {isExpanded ? '▲ 閉じる' : '▼ 詳細'}
          </button>
        </div>
      </div>

      {/* クリックで閉じるオーバーレイ */}
      {isActionMenuOpen && (
        <div 
          className="action-menu-overlay"
          onClick={() => setIsActionMenuOpen(false)}
        />
      )}
    </div>
  );
}

export default EntityCard;
```

### エンティティ作成・編集フォーム

```javascript
/**
 * 📝 エンティティ作成・編集フォームコンポーネント
 * エンティティの作成と編集を行うフォーム
 * AWS Amplify v6 generateClient 使用
 */

import React, { useState, useEffect } from 'react';
import { generateClient } from 'aws-amplify/api';
import { createEntity, updateEntity } from '../graphql/mutations';
import { listEntities, listEntitiesByUser } from '../graphql/queries';

const client = generateClient();

function EntityForm({ 
  entity = null, // 編集時は既存エンティティ、作成時はnull
  currentUser,
  onSuccess,
  onCancel,
  showOnlyUserEntities = false
}) {
  // 🔹 フォームの状態管理
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    status: 'ACTIVE'
  });
  const [errors, setErrors] = useState({});
  const [isSubmitting, setIsSubmitting] = useState(false);

  // 編集モードかどうかの判定
  const isEditMode = Boolean(entity);

  // 🔹 フォームの初期化
  useEffect(() => {
    if (entity) {
      setFormData({
        name: entity.name || '',
        description: entity.description || '',
        status: entity.status || 'ACTIVE'
      });
    }
  }, [entity]);

  // 🔹 バリデーション
  const validateForm = () => {
    const newErrors = {};

    if (!formData.name.trim()) {
      newErrors.name = 'エンティティ名は必須です';
    } else if (formData.name.length < 2) {
      newErrors.name = 'エンティティ名は2文字以上で入力してください';
    } else if (formData.name.length > 100) {
      newErrors.name = 'エンティティ名は100文字以内で入力してください';
    }

    if (formData.description && formData.description.length > 500) {
      newErrors.description = '説明は500文字以内で入力してください';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  // 🔹 フォーム送信処理
  const handleSubmit = async (e) => {
    e.preventDefault();

    if (!validateForm()) {
      return;
    }

    setIsSubmitting(true);

    try {
      let result;
      
      if (isEditMode) {
        // 更新処理
        result = await client.graphql({
          query: updateEntity,
          variables: {
            input: {
              id: entity.id,
              name: formData.name.trim(),
              description: formData.description.trim(),
              status: formData.status,
              updatedAt: new Date().toISOString()
            }
          }
        });

        console.log('エンティティが更新されました:', result.data.updateEntity);
        onSuccess && onSuccess(result.data.updateEntity, 'updated');
      } else {
        // 作成処理
        result = await client.graphql({
          query: createEntity,
          variables: {
            input: {
              name: formData.name.trim(),
              description: formData.description.trim(),
              status: formData.status,
              userId: currentUser.sub,
              createdAt: new Date().toISOString(),
              updatedAt: new Date().toISOString()
            }
          }
        });

        console.log('エンティティが作成されました:', result.data.createEntity);
        onSuccess && onSuccess(result.data.createEntity, 'created');
      }

      // フォームをリセット（作成モードの場合）
      if (!isEditMode) {
        setFormData({
          name: '',
          description: '',
          status: 'ACTIVE'
        });
      }

    } catch (error) {
      console.error('エンティティ保存エラー:', error);
      
      // エラーメッセージを設定
      if (error.errors && error.errors.length > 0) {
        const graphqlError = error.errors[0];
        if (graphqlError.errorType === 'ValidationException') {
          setErrors({ submit: 'データの形式が正しくありません' });
        } else if (graphqlError.errorType === 'UnauthorizedException') {
          setErrors({ submit: '操作する権限がありません' });
        } else {
          setErrors({ submit: graphqlError.message || '保存に失敗しました' });
        }
      } else {
        setErrors({ submit: '保存に失敗しました。もう一度お試しください。' });
      }
    } finally {
      setIsSubmitting(false);
    }
  };

  // 🔹 入力値変更ハンドラー
  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));

    // エラーをクリア
    if (errors[name]) {
      setErrors(prev => ({
        ...prev,
        [name]: ''
      }));
    }
  };

  // 🔹 キャンセル処理
  const handleCancel = () => {
    if (!isEditMode) {
      setFormData({
        name: '',
        description: '',
        status: 'ACTIVE'
      });
    }
    setErrors({});
    onCancel && onCancel();
  };

  return (
    <div className="entity-form">
      <div className="form-header">
        <h2>
          {isEditMode ? '✏️ エンティティ編集' : '🆕 新しいエンティティ'}
        </h2>
      </div>

      <form onSubmit={handleSubmit} className="form-content">
        {/* エンティティ名 */}
        <div className="field-group">
          <label htmlFor="name" className="field-label">
            エンティティ名 <span className="required">*</span>
          </label>
          <input
            type="text"
            id="name"
            name="name"
            value={formData.name}
            onChange={handleInputChange}
            className={`form-input ${errors.name ? 'error' : ''}`}
            placeholder="エンティティ名を入力..."
            maxLength={100}
            disabled={isSubmitting}
            autoComplete="off"
          />
          {errors.name && (
            <span className="error-message">{errors.name}</span>
          )}
        </div>

        {/* 説明 */}
        <div className="field-group">
          <label htmlFor="description" className="field-label">
            説明
          </label>
          <textarea
            id="description"
            name="description"
            value={formData.description}
            onChange={handleInputChange}
            className={`form-textarea ${errors.description ? 'error' : ''}`}
            placeholder="エンティティの説明を入力..."
            rows={4}
            maxLength={500}
            disabled={isSubmitting}
          />
          <div className="character-count">
            {formData.description.length} / 500
          </div>
          {errors.description && (
            <span className="error-message">{errors.description}</span>
          )}
        </div>

        {/* ステータス */}
        <div className="field-group">
          <label htmlFor="status" className="field-label">
            ステータス
          </label>
          <select
            id="status"
            name="status"
            value={formData.status}
            onChange={handleInputChange}
            className="form-select"
            disabled={isSubmitting}
          >
            <option value="ACTIVE">🟢 アクティブ</option>
            <option value="INACTIVE">🔴 非アクティブ</option>
            <option value="ARCHIVED">📦 アーカイブ</option>
          </select>
        </div>

        {/* 送信エラー */}
        {errors.submit && (
          <div className="submit-error">
            ❌ {errors.submit}
          </div>
        )}

        {/* アクションボタン */}
        <div className="form-actions">
          <button
            type="button"
            onClick={handleCancel}
            className="btn btn-secondary"
            disabled={isSubmitting}
          >
            キャンセル
          </button>
          
          <button
            type="submit"
            className="btn btn-primary"
            disabled={isSubmitting}
          >
            {isSubmitting ? (
              <>
                <span className="loading-spinner"></span>
                {isEditMode ? '更新中...' : '作成中...'}
              </>
            ) : (
              isEditMode ? '更新' : '作成'
            )}
          </button>
        </div>
      </form>
    </div>
export default EntityForm;
```

## 🎨 スタイリングとUIパターン

### CSSテンプレート

```css
/**
 * エンティティ関連コンポーネントのスタイリング
 * 一貫性のあるデザインシステムに基づいたスタイル
 */

/* 🔹 基本レイアウト */
.entity-list {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
  padding: 1rem;
}

.entities-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 1rem;
}

/* 🔹 統計情報セクション */
.stats-section {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 12px;
  padding: 1.5rem;
  color: white;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 1rem;
  margin-top: 1rem;
}

.stat-item {
  text-align: center;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 8px;
  padding: 1rem;
}

.stat-number {
  display: block;
  font-size: 2rem;
  font-weight: bold;
  margin-bottom: 0.25rem;
}

.stat-label {
  font-size: 0.875rem;
  opacity: 0.9;
}

/* 🔹 検索・フィルターコントロール */
.controls-section {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1rem;
  flex-wrap: wrap;
}

.search-input {
  flex: 1;
  min-width: 250px;
  padding: 0.75rem 1rem;
  border: 2px solid #e2e8f0;
  border-radius: 8px;
  font-size: 1rem;
  transition: border-color 0.2s;
}

.search-input:focus {
  outline: none;
  border-color: #4299e1;
  box-shadow: 0 0 0 3px rgba(66, 153, 225, 0.1);
}

.filter-buttons {
  display: flex;
  gap: 0.5rem;
}

.filter-buttons button {
  padding: 0.5rem 1rem;
  border: 2px solid #e2e8f0;
  background: white;
  border-radius: 6px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}

.filter-buttons button:hover {
  border-color: #cbd5e0;
}

.filter-buttons button.active {
  background: #4299e1;
  border-color: #4299e1;
  color: white;
}

/* 🔹 エンティティカードスタイル */
.entity-card {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  overflow: hidden;
  transition: all 0.2s;
  cursor: pointer;
}

.entity-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
  border-color: #cbd5e0;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  padding: 1rem;
  border-bottom: 1px solid #f7fafc;
}

.entity-name {
  font-size: 1.125rem;
  font-weight: 600;
  margin: 0 0 0.5rem 0;
  color: #2d3748;
}

.status-badge {
  display: flex;
  align-items: center;
  gap: 0.25rem;
  padding: 0.25rem 0.75rem;
  border-radius: 20px;
  font-size: 0.875rem;
  font-weight: 500;
}

.status-badge.active {
  background: #c6f6d5;
  color: #276749;
}

.status-badge.inactive {
  background: #fed7d7;
  color: #c53030;
}

.status-badge.archived {
  background: #e2e8f0;
  color: #4a5568;
}

.card-content {
  padding: 1rem;
}

.entity-description {
  color: #718096;
  line-height: 1.5;
  margin-bottom: 1rem;
}

.card-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.75rem 1rem;
  background: #f7fafc;
  font-size: 0.875rem;
  color: #718096;
}

/* 🔹 フォームスタイル */
.entity-form {
  max-width: 600px;
  margin: 0 auto;
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

.form-header {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 1.5rem;
  text-align: center;
}

.form-header h2 {
  margin: 0;
  font-size: 1.5rem;
  font-weight: 600;
}

.form-content {
  padding: 2rem;
}

.field-group {
  margin-bottom: 1.5rem;
}

.field-label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 600;
  color: #2d3748;
}

.required {
  color: #e53e3e;
}

.form-input,
.form-textarea,
.form-select {
  width: 100%;
  padding: 0.75rem;
  border: 2px solid #e2e8f0;
  border-radius: 8px;
  font-size: 1rem;
  transition: border-color 0.2s;
}

.form-input:focus,
.form-textarea:focus,
.form-select:focus {
  outline: none;
  border-color: #4299e1;
  box-shadow: 0 0 0 3px rgba(66, 153, 225, 0.1);
}

.form-input.error,
.form-textarea.error {
  border-color: #e53e3e;
}

.error-message {
  display: block;
  color: #e53e3e;
  font-size: 0.875rem;
  margin-top: 0.25rem;
}

.character-count {
  text-align: right;
  font-size: 0.75rem;
  color: #718096;
  margin-top: 0.25rem;
}

.submit-error {
  background: #fed7d7;
  color: #c53030;
  padding: 0.75rem;
  border-radius: 8px;
  margin-bottom: 1rem;
  text-align: center;
}

.form-actions {
  display: flex;
  gap: 1rem;
  justify-content: flex-end;
  margin-top: 2rem;
}

/* 🔹 ボタンスタイル */
.btn {
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 8px;
  font-size: 1rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
}

.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.btn-primary {
  background: #4299e1;
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background: #3182ce;
}

.btn-secondary {
  background: #e2e8f0;
  color: #4a5568;
}

.btn-secondary:hover:not(:disabled) {
  background: #cbd5e0;
}

.btn-danger {
  background: #e53e3e;
  color: white;
}

.btn-danger:hover:not(:disabled) {
  background: #c53030;
}

/* 🔹 ローディング・エラーコンポーネント */
.loading-spinner {
  display: inline-block;
  width: 16px;
  height: 16px;
  border: 2px solid transparent;
  border-top: 2px solid currentColor;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

.empty-state {
  text-align: center;
  padding: 3rem 1rem;
  color: #718096;
}

.empty-state p {
  margin: 0.5rem 0;
}

/* 🔹 レスポンシブデザイン */
@media (max-width: 768px) {
  .entities-grid {
    grid-template-columns: 1fr;
  }
  
  .controls-section {
    flex-direction: column;
    align-items: stretch;
  }
  
  .search-input {
    min-width: auto;
  }
  
  .stats-grid {
    grid-template-columns: repeat(2, 1fr);
  }
  
  .form-actions {
    flex-direction: column;
  }
}

@media (max-width: 480px) {
  .stats-grid {
    grid-template-columns: 1fr;
  }
}
```

## 🏗️ ベストプラクティス

### パフォーマンス最適化

```javascript
/**
 * 📈 パフォーマンス最適化のベストプラクティス
 * AWS Amplify v6対応
 */

// 1. 🎯 GraphQLクエリの最適化
// 必要なフィールドのみ選択
const /* GraphQL */ listEntitiesOptimized = `
  query ListEntitiesOptimized($limit: Int, $nextToken: String) {
    listEntities(limit: $limit, nextToken: $nextToken) {
      items {
        id
        name
        status
        updatedAt
        # 詳細は必要な時のみ取得
      }
      nextToken
    }
  }
`;

// 2. 🔄 リアルタイム更新の制御
const useOptimizedSubscription = (entityId, enabled = true) => {
  useEffect(() => {
    if (!enabled || !entityId) return;

    const subscription = client.graphql({
      query: onEntityUpdated,
      variables: { id: entityId }
    }).subscribe({
      next: ({ data }) => {
        // バッチ更新でDOM操作を削減
        requestAnimationFrame(() => {
          updateEntityState(data.onEntityUpdated);
        });
      }
    });

    return () => subscription.unsubscribe();
  }, [entityId, enabled]);
};

// 3. 📦 コンポーネントの遅延読み込み
const EntityForm = React.lazy(() => import('./EntityForm'));
const EntityDetails = React.lazy(() => import('./EntityDetails'));

function App() {
  return (
    <React.Suspense fallback={<LoadingSpinner />}>
      <EntityForm />
    </React.Suspense>
  );
}

// 4. 🏪 効率的な状態管理
const useEntityCache = () => {
  const [cache, setCache] = useState(new Map());
  
  const getEntity = useCallback(async (id) => {
    if (cache.has(id)) {
      return cache.get(id);
    }
    
    const result = await client.graphql({
      query: getEntityById,
      variables: { id }
    });
    
    setCache(prev => new Map(prev).set(id, result.data.getEntity));
    return result.data.getEntity;
  }, [cache]);
  
  return { getEntity, cache };
};
```

### エラーハンドリング

```javascript
/**
 * 🛡️ 堅牢なエラーハンドリング戦略
 * AWS Amplify v6エラーパターンに対応
 */

// 1. 🎯 GraphQLエラーの分類と処理
const handleGraphQLError = (error) => {
  console.error('GraphQL Error:', error);
  
  if (error.errors) {
    error.errors.forEach(err => {
      switch (err.errorType) {
        case 'UnauthorizedException':
          // 認証エラー
          redirectToLogin();
          break;
        case 'ValidationException':
          // バリデーションエラー
          showValidationErrors(err.message);
          break;
        case 'ConflictException':
          // 競合エラー
          showConflictResolution();
          break;
        case 'DynamoDB:ConditionalCheckFailedException':
          // 楽観的ロック失敗
          showOptimisticLockError();
          break;
        default:
          // その他のエラー
          showGenericError(err.message);
      }
    });
  }
};

// 2. 🔄 リトライ機能付きAPI呼び出し
const executeWithRetry = async (operation, maxRetries = 3) => {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await operation();
    } catch (error) {
      if (attempt === maxRetries) {
        throw error;
      }
      
      // 指数バックオフ
      const delay = Math.pow(2, attempt) * 1000;
      await new Promise(resolve => setTimeout(resolve, delay));
      console.log(`リトライ ${attempt}/${maxRetries}...`);
    }
  }
};

// 3. 🌐 ネットワークエラーの処理
const useNetworkStatus = () => {
  const [isOnline, setIsOnline] = useState(navigator.onLine);
  
  useEffect(() => {
    const handleOnline = () => setIsOnline(true);
    const handleOffline = () => setIsOnline(false);
    
    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);
    
    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);
  
  return isOnline;
};

// 4. 📊 エラー報告とロギング
const logError = (error, context = {}) => {
  const errorReport = {
    message: error.message,
    stack: error.stack,
    timestamp: new Date().toISOString(),
    userId: context.userId,
    component: context.component,
    action: context.action,
    userAgent: navigator.userAgent,
    url: window.location.href
  };
  
  // 本番環境では外部サービスに送信
  if (process.env.NODE_ENV === 'production') {
    sendErrorToLoggingService(errorReport);
  } else {
    console.error('Error Report:', errorReport);
  }
};
```

### アクセシビリティ

```javascript
/**
 * ♿ アクセシビリティのベストプラクティス
 * WCAG 2.1 AA準拠
 */

// 1. 🎯 適切なARIA属性
function AccessibleEntityCard({ entity, isSelected, onSelect }) {
  return (
    <div
      role="button"
      tabIndex={0}
      aria-label={`エンティティ: ${entity.name}. ステータス: ${entity.status}`}
      aria-selected={isSelected}
      className={`entity-card ${isSelected ? 'selected' : ''}`}
      onClick={onSelect}
      onKeyDown={(e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          onSelect();
        }
      }}
    >
      <h3 id={`entity-${entity.id}-title`}>
        {entity.name}
      </h3>
      <p aria-describedby={`entity-${entity.id}-title`}>
        {entity.description}
      </p>
    </div>
  );
}

// 2. 🔧 フォームアクセシビリティ
function AccessibleForm() {
  const [errors, setErrors] = useState({});
  
  return (
    <form role="form" aria-label="エンティティフォーム">
      <div className="field-group">
        <label htmlFor="entity-name">
          エンティティ名
          <span aria-label="必須項目">*</span>
        </label>
        <input
          id="entity-name"
          type="text"
          aria-required="true"
          aria-invalid={errors.name ? 'true' : 'false'}
          aria-describedby={errors.name ? 'name-error' : undefined}
        />
        {errors.name && (
          <span id="name-error" role="alert" className="error-message">
            {errors.name}
          </span>
        )}
      </div>
    </form>
  );
}

// 3. 🔄 ライブリージョンによる動的更新の通知
function LiveUpdates() {
  const [announcement, setAnnouncement] = useState('');
  
  const announceUpdate = (message) => {
    setAnnouncement(message);
    // メッセージをクリア
    setTimeout(() => setAnnouncement(''), 1000);
  };
  
  return (
    <>
      <div
        aria-live="polite"
        aria-atomic="true"
        className="sr-only"
      >
        {announcement}
      </div>
      
      <button
        onClick={() => {
          saveEntity();
          announceUpdate('エンティティが保存されました');
        }}
      >
        保存
      </button>
    </>
  );
}
```
  });

  // 🔹 バリデーション
  const validateForm = () => {
    const newErrors = {};

    // 名前の検証
    if (!formData.name.trim()) {
      newErrors.name = '名前は必須です';
    } else if (formData.name.length > 100) {
      newErrors.name = '名前は100文字以内で入力してください';
    }

    // 説明の検証
    if (formData.description.length > 1000) {
      newErrors.description = '説明は1000文字以内で入力してください';
    }

    // ステータスの検証
    if (!['ACTIVE', 'INACTIVE', 'PENDING'].includes(formData.status)) {
      newErrors.status = '有効なステータスを選択してください';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  // 🔹 イベントハンドラー
  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));

    // 入力時にエラーをクリア
    if (errors[name]) {
      setErrors(prev => ({
        ...prev,
        [name]: undefined
      }));
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!validateForm()) {
      return;
    }

    setIsSubmitting(true);
    setErrors({});

    try {
      if (isEditMode) {
        // 更新処理
        await updateEntity({
          variables: {
            input: {
              id: entity.id,
              name: formData.name.trim(),
              description: formData.description.trim(),
              status: formData.status,
              version: entity.version // 楽観的ロック用
            }
          }
        });
      } else {
        // 作成処理
        await createEntity({
          variables: {
            input: {
              name: formData.name.trim(),
              description: formData.description.trim(),
              status: formData.status
            }
          }
        });
      }
    } catch (error) {
      console.error('フォーム送信エラー:', error);
      // エラーはミューテーションのonErrorで処理
    } finally {
      setIsSubmitting(false);
    }
  };

  // 🔹 レンダリング
  return (
    <div className="entity-form-container">
      <form onSubmit={handleSubmit} className="entity-form">
        <h2>
          {isEditMode ? '✏️ エンティティを編集' : '📝 新しいエンティティを作成'}
        </h2>

        {/* エラーメッセージ */}
        {errors.submit && (
          <div className="error-message">
            ❌ {errors.submit}
          </div>
        )}

        {/* 名前フィールド */}
        <div className="form-group">
          <label htmlFor="name" className="form-label">
            名前 <span className="required">*</span>
          </label>
          <input
            type="text"
            id="name"
            name="name"
            value={formData.name}
            onChange={handleInputChange}
            className={`form-input ${errors.name ? 'error' : ''}`}
            placeholder="エンティティの名前を入力してください"
            maxLength={100}
            disabled={isSubmitting}
          />
          {errors.name && (
            <span className="field-error">{errors.name}</span>
          )}
          <span className="char-count">{formData.name.length}/100</span>
        </div>

        {/* 説明フィールド */}
        <div className="form-group">
          <label htmlFor="description" className="form-label">
            説明
          </label>
          <textarea
            id="description"
            name="description"
            value={formData.description}
            onChange={handleInputChange}
            className={`form-textarea ${errors.description ? 'error' : ''}`}
            placeholder="エンティティの説明を入力してください（任意）"
            rows={4}
            maxLength={1000}
            disabled={isSubmitting}
          />
          {errors.description && (
            <span className="field-error">{errors.description}</span>
          )}
          <span className="char-count">{formData.description.length}/1000</span>
        </div>

        {/* ステータスフィールド */}
        <div className="form-group">
          <label htmlFor="status" className="form-label">
            ステータス
          </label>
          <select
            id="status"
            name="status"
            value={formData.status}
            onChange={handleInputChange}
            className={`form-select ${errors.status ? 'error' : ''}`}
            disabled={isSubmitting}
          >
            <option value="ACTIVE">✅ アクティブ</option>
            <option value="INACTIVE">⏸️ 非アクティブ</option>
            <option value="PENDING">⏳ 保留中</option>
          </select>
          {errors.status && (
            <span className="field-error">{errors.status}</span>
          )}
        </div>

        {/* ボタン */}
        <div className="form-actions">
          <button
            type="button"
            onClick={onCancel}
            className="button button-secondary"
            disabled={isSubmitting}
          >
            キャンセル
          </button>
          <button
            type="submit"
            className="button button-primary"
            disabled={isSubmitting}
          >
            {isSubmitting 
              ? (isEditMode ? '更新中...' : '作成中...') 
              : (isEditMode ? '✏️ 更新' : '📝 作成')
            }
          </button>
        </div>
      </form>
    </div>
  );
}

export default EntityForm;
```

## 🎯 使用方法

1. **適切なテンプレートを選択**
   - GraphQL操作：queries.js, mutations.js, subscriptions.js
   - 一覧表示：EntityList コンポーネント
   - 詳細表示：EntityCard コンポーネント  
   - 作成・編集：EntityForm コンポーネント

2. **カスタマイズ**
   - `Entity` を実際のエンティティ名に変更
   - フィールド名やバリデーションルールを調整
   - UIスタイルを自分のデザインに合わせて修正

3. **段階的実装**
   - まずはクエリとシンプルなリストから始める
   - 次にミューテーションとフォームを追加
   - 最後にサブスクリプションでリアルタイム機能を実装

---

**💡 これらのテンプレートを組み合わせて、React + AppSync の powerful なフロントエンドを効率的に構築できます！**

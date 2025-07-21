# ⚛️ React フロントエンドテンプレート

このファイルには、AWS AppSync と連携するReactコンポーネントのテンプレートが含まれています。

## 📡 GraphQL操作定義テンプレート

### クエリテンプレート（src/graphql/queries.js）

```javascript
/**
 * 📖 GraphQLクエリ定義
 * データ取得用のクエリを定義します
 */

import { gql } from '@apollo/client';

// 🔍 単一エンティティ取得
export const GET_ENTITY = gql`
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
export const LIST_ENTITIES = gql`
  query ListEntities($userId: String, $status: EntityStatus, $limit: Int, $nextToken: String) {
    listEntities(userId: $userId, status: $status, limit: $limit, nextToken: $nextToken) {
      items {
        id
        name
        description
        status
        userId
        createdAt
        updatedAt
        itemCount
      }
      nextToken             # 次ページのトークン
      total                 # 総件数
    }
  }
`;

// 🔍 ユーザー別エンティティ取得
export const LIST_ENTITIES_BY_USER = gql`
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
export const SEARCH_ENTITIES = gql`
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
export const GET_ENTITY_STATS = gql`
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
 */

import { gql } from '@apollo/client';

// 📝 エンティティ作成
export const CREATE_ENTITY = gql`
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
export const UPDATE_ENTITY = gql`
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
export const DELETE_ENTITY = gql`
  mutation DeleteEntity($id: ID!) {
    deleteEntity(id: $id) {
      id                    # 削除されたエンティティのID
      name                  # 削除されたエンティティの名前
      deletedAt: updatedAt  # 削除日時
    }
  }
`;

// 🔄 ステータス変更
export const ACTIVATE_ENTITY = gql`
  mutation ActivateEntity($id: ID!) {
    activateEntity(id: $id) {
      id
      name
      status                # 'ACTIVE' になる
      updatedAt
    }
  }
`;

export const DEACTIVATE_ENTITY = gql`
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
export const ADD_ENTITY_TO_USER = gql`
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
 */

import { gql } from '@apollo/client';

// 🆕 エンティティ作成通知
export const ON_ENTITY_CREATED = gql`
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
export const ON_ENTITY_UPDATED = gql`
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
export const ON_ENTITY_DELETED = gql`
  subscription OnEntityDeleted($userId: String) {
    onEntityDeleted(userId: $userId) {
      id                    # 削除されたエンティティのID
      name                  # 削除されたエンティティの名前
      userId                # 元の所有者ID
    }
  }
`;

// 🔄 ステータス変更通知
export const ON_ENTITY_STATUS_CHANGED = gql`
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
export const ON_USER_ENTITY_CHANGED = gql`
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
 */

import React, { useState, useEffect } from 'react';
import { useQuery, useMutation, useSubscription } from '@apollo/client';
import { 
  LIST_ENTITIES, 
  LIST_ENTITIES_BY_USER,
  GET_ENTITY_STATS 
} from '../graphql/queries';
import { 
  DELETE_ENTITY, 
  ACTIVATE_ENTITY, 
  DEACTIVATE_ENTITY 
} from '../graphql/mutations';
import { 
  ON_ENTITY_CREATED, 
  ON_ENTITY_UPDATED, 
  ON_ENTITY_DELETED 
} from '../graphql/subscriptions';
import EntityCard from './EntityCard';
import LoadingSpinner from './LoadingSpinner';
import ErrorMessage from './ErrorMessage';

function EntityList({ userId, showOnlyUserEntities = false, currentUser }) {
  // 🔹 状態管理
  const [entities, setEntities] = useState([]);
  const [filter, setFilter] = useState('ALL'); // ALL, ACTIVE, INACTIVE
  const [searchKeyword, setSearchKeyword] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);

  // 🔹 GraphQLクエリの実行
  const { 
    data: entitiesData, 
    loading: entitiesLoading, 
    error: entitiesError,
    refetch: refetchEntities,
    fetchMore
  } = useQuery(
    showOnlyUserEntities ? LIST_ENTITIES_BY_USER : LIST_ENTITIES, 
    {
      variables: {
        ...(showOnlyUserEntities && { userId }),
        ...(filter !== 'ALL' && { status: filter }),
        limit: 20
      },
      // キャッシュポリシー
      fetchPolicy: 'cache-and-network',
      // エラーポリシー
      errorPolicy: 'all'
    }
  );

  // 🔹 統計データの取得
  const { 
    data: statsData, 
    loading: statsLoading 
  } = useQuery(GET_ENTITY_STATS, {
    variables: showOnlyUserEntities ? { userId } : {},
    fetchPolicy: 'cache-first'
  });

  // 🔹 ミューテーションの準備
  const [deleteEntity] = useMutation(DELETE_ENTITY, {
    // 削除後の処理
    update(cache, { data: { deleteEntity } }) {
      // キャッシュから削除されたエンティティを除去
      const existingEntities = cache.readQuery({
        query: showOnlyUserEntities ? LIST_ENTITIES_BY_USER : LIST_ENTITIES,
        variables: {
          ...(showOnlyUserEntities && { userId }),
          ...(filter !== 'ALL' && { status: filter })
        }
      });

      if (existingEntities) {
        cache.writeQuery({
          query: showOnlyUserEntities ? LIST_ENTITIES_BY_USER : LIST_ENTITIES,
          variables: {
            ...(showOnlyUserEntities && { userId }),
            ...(filter !== 'ALL' && { status: filter })
          },
          data: {
            [showOnlyUserEntities ? 'listEntitiesByUser' : 'listEntities']: {
              ...existingEntities[showOnlyUserEntities ? 'listEntitiesByUser' : 'listEntities'],
              items: existingEntities[showOnlyUserEntities ? 'listEntitiesByUser' : 'listEntities'].items
                .filter(entity => entity.id !== deleteEntity.id)
            }
          }
        });
      }
    },
    // エラーハンドリング
    onError: (error) => {
      console.error('エンティティ削除エラー:', error);
      setError('エンティティの削除に失敗しました');
    }
  });

  const [activateEntity] = useMutation(ACTIVATE_ENTITY, {
    onError: (error) => {
      console.error('エンティティ有効化エラー:', error);
      setError('エンティティの有効化に失敗しました');
    }
  });

  const [deactivateEntity] = useMutation(DEACTIVATE_ENTITY, {
    onError: (error) => {
      console.error('エンティティ無効化エラー:', error);
      setError('エンティティの無効化に失敗しました');
    }
  });

  // 🔹 リアルタイム通知の受信
  useSubscription(ON_ENTITY_CREATED, {
    variables: showOnlyUserEntities ? { userId } : {},
    onSubscriptionData: ({ subscriptionData }) => {
      console.log('新しいエンティティが作成されました:', subscriptionData.data);
      
      // 新しいエンティティを一覧に追加
      const newEntity = subscriptionData.data.onEntityCreated;
      setEntities(prev => [newEntity, ...prev]);
    }
  });

  useSubscription(ON_ENTITY_UPDATED, {
    onSubscriptionData: ({ subscriptionData }) => {
      console.log('エンティティが更新されました:', subscriptionData.data);
      
      // 更新されたエンティティを一覧で更新
      const updatedEntity = subscriptionData.data.onEntityUpdated;
      setEntities(prev => 
        prev.map(entity => 
          entity.id === updatedEntity.id ? { ...entity, ...updatedEntity } : entity
        )
      );
    }
  });

  useSubscription(ON_ENTITY_DELETED, {
    variables: showOnlyUserEntities ? { userId } : {},
    onSubscriptionData: ({ subscriptionData }) => {
      console.log('エンティティが削除されました:', subscriptionData.data);
      
      // 削除されたエンティティを一覧から除去
      const deletedEntity = subscriptionData.data.onEntityDeleted;
      setEntities(prev => prev.filter(entity => entity.id !== deletedEntity.id));
    }
  });

  // 🔹 データ更新の処理
  useEffect(() => {
    if (entitiesData) {
      const items = showOnlyUserEntities 
        ? entitiesData.listEntitiesByUser 
        : entitiesData.listEntities?.items || entitiesData.listEntities;
      
      setEntities(Array.isArray(items) ? items : []);
      setIsLoading(false);
    }
  }, [entitiesData, showOnlyUserEntities]);

  // 🔹 エラー処理
  useEffect(() => {
    if (entitiesError) {
      setError('エンティティの取得に失敗しました');
      setIsLoading(false);
    }
  }, [entitiesError]);

  // 🔹 フィルタリング処理
  const filteredEntities = entities.filter(entity => {
    // 検索キーワードでフィルタ
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
        await deleteEntity({
          variables: { id: entityId }
        });
      } catch (error) {
        console.error('削除処理でエラー:', error);
      }
    }
  };

  const handleStatusToggle = async (entity) => {
    try {
      if (entity.status === 'ACTIVE') {
        await deactivateEntity({
          variables: { id: entity.id }
        });
      } else {
        await activateEntity({
          variables: { id: entity.id }
        });
      }
    } catch (error) {
      console.error('ステータス変更でエラー:', error);
    }
  };

  const handleLoadMore = () => {
    if (entitiesData?.listEntities?.nextToken) {
      fetchMore({
        variables: {
          nextToken: entitiesData.listEntities.nextToken
        }
      });
    }
  };

  // 🔹 レンダリング
  if (isLoading || entitiesLoading) {
    return <LoadingSpinner message="エンティティを読み込み中..." />;
  }

  if (error || entitiesError) {
    return (
      <ErrorMessage 
        message={error || entitiesError.message} 
        onRetry={() => {
          setError(null);
          refetchEntities();
        }}
      />
    );
  }

  return (
    <div className="entity-list">
      {/* 📊 統計情報 */}
      {statsData && !statsLoading && (
        <div className="stats-section">
          <h3>📊 統計情報</h3>
          <div className="stats-grid">
            <div className="stat-item">
              <span className="stat-number">{statsData.getEntityStats.total}</span>
              <span className="stat-label">総数</span>
            </div>
            <div className="stat-item">
              <span className="stat-number">{statsData.getEntityStats.activeCount}</span>
              <span className="stat-label">アクティブ</span>
            </div>
            <div className="stat-item">
              <span className="stat-number">{statsData.getEntityStats.inactiveCount}</span>
              <span className="stat-label">非アクティブ</span>
            </div>
            <div className="stat-item">
              <span className="stat-number">{statsData.getEntityStats.todayCreated}</span>
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

      {/* 📄 ページング */}
      {entitiesData?.listEntities?.nextToken && (
        <div className="pagination">
          <button onClick={handleLoadMore} className="load-more-btn">
            さらに読み込む
          </button>
        </div>
      )}
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
 */

import React, { useState, useEffect } from 'react';
import { useMutation } from '@apollo/client';
import { CREATE_ENTITY, UPDATE_ENTITY } from '../graphql/mutations';
import { LIST_ENTITIES, LIST_ENTITIES_BY_USER } from '../graphql/queries';

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

  // 🔹 ミューテーションの準備
  const [createEntity] = useMutation(CREATE_ENTITY, {
    // 作成後のキャッシュ更新
    update(cache, { data: { createEntity } }) {
      try {
        // 既存のクエリキャッシュに新しいエンティティを追加
        const existingEntities = cache.readQuery({
          query: showOnlyUserEntities ? LIST_ENTITIES_BY_USER : LIST_ENTITIES,
          variables: {
            ...(showOnlyUserEntities && { userId: currentUser?.sub })
          }
        });

        if (existingEntities) {
          cache.writeQuery({
            query: showOnlyUserEntities ? LIST_ENTITIES_BY_USER : LIST_ENTITIES,
            variables: {
              ...(showOnlyUserEntities && { userId: currentUser?.sub })
            },
            data: {
              [showOnlyUserEntities ? 'listEntitiesByUser' : 'listEntities']: [
                createEntity,
                ...(Array.isArray(existingEntities[showOnlyUserEntities ? 'listEntitiesByUser' : 'listEntities']) 
                   ? existingEntities[showOnlyUserEntities ? 'listEntitiesByUser' : 'listEntities']
                   : existingEntities[showOnlyUserEntities ? 'listEntitiesByUser' : 'listEntities']?.items || [])
              ]
            }
          });
        }
      } catch (error) {
        console.error('キャッシュ更新エラー:', error);
        // キャッシュ更新に失敗してもエラーにはしない
      }
    },
    onCompleted: (data) => {
      console.log('エンティティ作成完了:', data.createEntity);
      onSuccess && onSuccess(data.createEntity);
    },
    onError: (error) => {
      console.error('エンティティ作成エラー:', error);
      setErrors({ submit: 'エンティティの作成に失敗しました' });
    }
  });

  const [updateEntity] = useMutation(UPDATE_ENTITY, {
    onCompleted: (data) => {
      console.log('エンティティ更新完了:', data.updateEntity);
      onSuccess && onSuccess(data.updateEntity);
    },
    onError: (error) => {
      console.error('エンティティ更新エラー:', error);
      if (error.message.includes('ConflictError')) {
        setErrors({ submit: 'このエンティティは他のユーザーによって更新されています。ページを再読み込みしてください。' });
      } else {
        setErrors({ submit: 'エンティティの更新に失敗しました' });
      }
    }
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

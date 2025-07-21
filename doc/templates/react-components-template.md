# 🧩 React コンポーネントテンプレート

このファイルには、AWS AppSync と連携するReactコンポーネントのテンプレートが含まれています。
**AWS Amplify v6** の `generateClient` を使用した実装例です。

## 📋 エンティティ一覧コンポーネント

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

## 🎴 エンティティカードコンポーネント

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
        return { label: '非アクティブ', className: 'status-inactive', emoji: '❌' };
      default:
        return { label: '不明', className: 'status-unknown', emoji: '❓' };
    }
  };

  const statusConfig = getStatusConfig(entity.status);

  return (
    <div className={`entity-card ${entity.status?.toLowerCase()}`}>
      {/* 📌 ヘッダー部分 */}
      <div className="card-header">
        <div className="entity-title">
          <h3>{entity.name}</h3>
          <span className={`status-badge ${statusConfig.className}`}>
            {statusConfig.emoji} {statusConfig.label}
          </span>
        </div>
        
        {/* ⚙️ アクションメニュー */}
        {(canEdit || canDelete) && (
          <div className="action-menu">
            <button 
              className="menu-trigger"
              onClick={() => setIsActionMenuOpen(!isActionMenuOpen)}
              aria-label="アクション"
            >
              ⋮
            </button>
            
            {isActionMenuOpen && (
              <div className="menu-dropdown">
                {canEdit && (
                  <>
                    <button onClick={onEdit} className="menu-item">
                      ✏️ 編集
                    </button>
                    <button onClick={onStatusToggle} className="menu-item">
                      🔄 ステータス変更
                    </button>
                  </>
                )}
                {canDelete && (
                  <button onClick={onDelete} className="menu-item danger">
                    🗑️ 削除
                  </button>
                )}
              </div>
            )}
          </div>
        )}
      </div>

      {/* 📝 説明部分 */}
      {entity.description && (
        <div className="card-description">
          <p className={isExpanded ? 'expanded' : 'truncated'}>
            {entity.description}
          </p>
          {entity.description.length > 100 && (
            <button 
              className="expand-button"
              onClick={() => setIsExpanded(!isExpanded)}
            >
              {isExpanded ? '折りたたみ' : 'もっと見る'}
            </button>
          )}
        </div>
      )}

      {/* 📊 メタデータ */}
      <div className="card-metadata">
        <div className="metadata-item">
          <span className="label">作成者:</span>
          <span className="value">{entity.userId}</span>
        </div>
        <div className="metadata-item">
          <span className="label">作成日:</span>
          <span className="value">{formatDate(entity.createdAt)}</span>
        </div>
        {entity.updatedAt && entity.updatedAt !== entity.createdAt && (
          <div className="metadata-item">
            <span className="label">更新日:</span>
            <span className="value">{formatDate(entity.updatedAt)}</span>
          </div>
        )}
        {entity.itemCount !== undefined && (
          <div className="metadata-item">
            <span className="label">関連アイテム:</span>
            <span className="value">{entity.itemCount}件</span>
          </div>
        )}
      </div>

      {/* 🔗 関連アイテム表示 */}
      {entity.relatedItems && entity.relatedItems.length > 0 && (
        <div className="related-items">
          <h4>関連アイテム</h4>
          <ul>
            {entity.relatedItems.slice(0, 3).map(item => (
              <li key={item.id}>
                <span className="item-name">{item.name}</span>
                <span className="item-date">{formatDate(item.createdAt)}</span>
              </li>
            ))}
          </ul>
          {entity.relatedItems.length > 3 && (
            <p className="more-items">
              他 {entity.relatedItems.length - 3} 件
            </p>
          )}
        </div>
      )}
    </div>
  );
}

export default EntityCard;
```

## ⚠️ エラー境界コンポーネント

```javascript
/**
 * ⚠️ エラー境界コンポーネント
 * 子コンポーネントでのエラーをキャッチし、適切に処理します
 */

import React from 'react';

class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { 
      hasError: false, 
      error: null, 
      errorInfo: null 
    };
  }

  static getDerivedStateFromError(error) {
    // エラーが発生したときに state を更新
    return { hasError: true };
  }

  componentDidCatch(error, errorInfo) {
    // エラーログを記録
    console.error('ErrorBoundary がエラーをキャッチしました:', error, errorInfo);
    
    this.setState({
      error: error,
      errorInfo: errorInfo
    });

    // 本番環境では外部のエラー追跡サービスに送信
    if (process.env.NODE_ENV === 'production') {
      // 例: Sentry, CloudWatch Logs 等にエラーを送信
      this.logErrorToService(error, errorInfo);
    }
  }

  logErrorToService = (error, errorInfo) => {
    // エラー追跡サービスへの送信ロジック
    try {
      const errorData = {
        message: error.message,
        stack: error.stack,
        componentStack: errorInfo.componentStack,
        timestamp: new Date().toISOString(),
        userAgent: navigator.userAgent,
        url: window.location.href
      };
      
      // ここで外部サービスにエラーデータを送信
      console.log('エラーログをサービスに送信:', errorData);
    } catch (logError) {
      console.error('エラーログの送信に失敗:', logError);
    }
  };

  handleReset = () => {
    this.setState({ 
      hasError: false, 
      error: null, 
      errorInfo: null 
    });
  };

  render() {
    if (this.state.hasError) {
      return (
        <div className="error-boundary">
          <div className="error-content">
            <h2>⚠️ 予期しないエラーが発生しました</h2>
            <p>申し訳ございません。アプリケーションでエラーが発生しました。</p>
            
            <div className="error-actions">
              <button 
                onClick={this.handleReset}
                className="retry-button"
              >
                🔄 再試行
              </button>
              <button 
                onClick={() => window.location.reload()}
                className="reload-button"
              >
                🔄 ページを再読み込み
              </button>
            </div>

            {/* 開発環境でのみエラー詳細を表示 */}
            {process.env.NODE_ENV === 'development' && (
              <details className="error-details">
                <summary>エラー詳細 (開発環境のみ)</summary>
                <pre>{this.state.error && this.state.error.toString()}</pre>
                <pre>{this.state.errorInfo.componentStack}</pre>
              </details>
            )}
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}

export default ErrorBoundary;
```

## 🔄 ローディングスピナーコンポーネント

```javascript
/**
 * 🔄 ローディングスピナーコンポーネント
 * データ読み込み中の表示を行います
 */

import React from 'react';

function LoadingSpinner({ 
  message = 'データを読み込み中...', 
  size = 'medium',
  overlay = false 
}) {
  const sizeClasses = {
    small: 'spinner-small',
    medium: 'spinner-medium', 
    large: 'spinner-large'
  };

  return (
    <div className={`loading-spinner ${overlay ? 'overlay' : ''}`}>
      <div className="spinner-container">
        <div className={`spinner ${sizeClasses[size]}`}>
          <div className="bounce1"></div>
          <div className="bounce2"></div>
          <div className="bounce3"></div>
        </div>
        {message && (
          <p className="loading-message">{message}</p>
        )}
      </div>
    </div>
  );
}

// より高度なプログレスバー付きローディング
function LoadingProgress({ 
  message = 'データを読み込み中...', 
  progress = 0,
  showProgress = false 
}) {
  return (
    <div className="loading-progress">
      <div className="progress-container">
        <div className="progress-message">{message}</div>
        {showProgress && (
          <>
            <div className="progress-bar">
              <div 
                className="progress-fill"
                style={{ width: `${Math.min(progress, 100)}%` }}
              ></div>
            </div>
            <div className="progress-text">{progress}%</div>
          </>
        )}
      </div>
    </div>
  );
}

export default LoadingSpinner;
export { LoadingProgress };
```

## 💬 エラーメッセージコンポーネント

```javascript
/**
 * 💬 エラーメッセージコンポーネント
 * エラー状態の表示と再試行機能を提供します
 */

import React from 'react';

function ErrorMessage({ 
  message, 
  error = null, 
  onRetry = null, 
  type = 'error' // 'error', 'warning', 'info'
}) {
  const getIconForType = (type) => {
    switch (type) {
      case 'warning': return '⚠️';
      case 'info': return 'ℹ️';
      case 'error':
      default: return '❌';
    }
  };

  const getClassForType = (type) => {
    switch (type) {
      case 'warning': return 'message-warning';
      case 'info': return 'message-info';
      case 'error':
      default: return 'message-error';
    }
  };

  return (
    <div className={`error-message ${getClassForType(type)}`}>
      <div className="message-content">
        <div className="message-header">
          <span className="message-icon">{getIconForType(type)}</span>
          <h3 className="message-title">
            {type === 'error' ? 'エラーが発生しました' : 
             type === 'warning' ? '警告' : '情報'}
          </h3>
        </div>
        
        <p className="message-text">{message}</p>
        
        {/* 開発環境でのエラー詳細 */}
        {error && process.env.NODE_ENV === 'development' && (
          <details className="error-details">
            <summary>エラー詳細 (開発環境のみ)</summary>
            <pre>{error.toString()}</pre>
            {error.stack && <pre>{error.stack}</pre>}
          </details>
        )}
        
        {/* 再試行ボタン */}
        {onRetry && (
          <div className="message-actions">
            <button 
              onClick={onRetry}
              className="retry-button"
            >
              🔄 再試行
            </button>
          </div>
        )}
      </div>
    </div>
  );
}

export default ErrorMessage;
```

## 🎯 使用方法

### 1. ファイルの配置
```
src/
├── components/
│   ├── EntityList.jsx          # エンティティ一覧
│   ├── EntityCard.jsx          # エンティティカード
│   ├── ErrorBoundary.jsx       # エラー境界
│   ├── LoadingSpinner.jsx      # ローディング表示
│   └── ErrorMessage.jsx        # エラーメッセージ
```

### 2. 使用例
```javascript
import React from 'react';
import ErrorBoundary from './components/ErrorBoundary';
import EntityList from './components/EntityList';

function App() {
  return (
    <div className="app">
      <ErrorBoundary>
        <EntityList 
          showOnlyUserEntities={false}
          currentUser={currentUser}
        />
      </ErrorBoundary>
    </div>
  );
}
```

## 🔗 関連テンプレート

- [React GraphQL操作テンプレート](./react-graphql-template.md) - GraphQL操作の実装
- [React フォームテンプレート](./react-forms-template.md) - フォーム処理の実装
- [React スタイリングテンプレート](./react-styling-template.md) - CSSとUIパターン

# 📝 React フォームテンプレート

このファイルには、AWS AppSync と連携するReactフォームコンポーネントのテンプレートが含まれています。
バリデーション、エラーハンドリング、最適化されたUXを含む包括的なフォーム実装例です。

## 📝 エンティティ作成・編集フォーム

```javascript
/**
 * 📝 エンティティ作成・編集フォームコンポーネント
 * エンティティの作成と編集を行うフォーム
 * AWS Amplify v6 generateClient 使用
 */

import React, { useState, useEffect } from 'react';
import { generateClient } from 'aws-amplify/api';
import { createEntity, updateEntity } from '../graphql/mutations';

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
  );
}

export default EntityForm;
```

## 🔍 高度な検索フォーム

```javascript
/**
 * 🔍 高度な検索フォームコンポーネント
 * 複数条件での検索機能を提供
 */

import React, { useState, useEffect } from 'react';
import { generateClient } from 'aws-amplify/api';
import { searchEntities } from '../graphql/queries';

const client = generateClient();

function AdvancedSearchForm({ onSearchResults, onReset }) {
  const [searchForm, setSearchForm] = useState({
    keyword: '',
    status: '',
    createdDateFrom: '',
    createdDateTo: '',
    userId: '',
    sortBy: 'createdAt',
    sortOrder: 'desc'
  });
  const [isSearching, setIsSearching] = useState(false);
  const [searchHistory, setSearchHistory] = useState([]);

  // 🔹 検索履歴の読み込み
  useEffect(() => {
    const savedHistory = localStorage.getItem('searchHistory');
    if (savedHistory) {
      setSearchHistory(JSON.parse(savedHistory));
    }
  }, []);

  // 🔹 検索実行
  const handleSearch = async (e) => {
    e.preventDefault();
    
    if (!searchForm.keyword.trim() && !searchForm.status && !searchForm.userId) {
      alert('検索条件を少なくとも1つ入力してください');
      return;
    }

    setIsSearching(true);

    try {
      const variables = {
        keyword: searchForm.keyword.trim(),
        ...(searchForm.status && { status: searchForm.status }),
        ...(searchForm.userId && { userId: searchForm.userId }),
        ...(searchForm.createdDateFrom && { createdDateFrom: searchForm.createdDateFrom }),
        ...(searchForm.createdDateTo && { createdDateTo: searchForm.createdDateTo }),
        sortBy: searchForm.sortBy,
        sortOrder: searchForm.sortOrder,
        limit: 50
      };

      const result = await client.graphql({
        query: searchEntities,
        variables
      });

      const results = result.data.searchEntities;
      onSearchResults && onSearchResults(results, searchForm);

      // 検索履歴に追加
      if (searchForm.keyword.trim()) {
        const newHistory = [
          searchForm.keyword.trim(),
          ...searchHistory.filter(item => item !== searchForm.keyword.trim())
        ].slice(0, 10); // 最新10件まで保持
        
        setSearchHistory(newHistory);
        localStorage.setItem('searchHistory', JSON.stringify(newHistory));
      }

    } catch (error) {
      console.error('検索エラー:', error);
      alert('検索に失敗しました');
    } finally {
      setIsSearching(false);
    }
  };

  // 🔹 フォームリセット
  const handleReset = () => {
    setSearchForm({
      keyword: '',
      status: '',
      createdDateFrom: '',
      createdDateTo: '',
      userId: '',
      sortBy: 'createdAt',
      sortOrder: 'desc'
    });
    onReset && onReset();
  };

  // 🔹 入力値変更
  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setSearchForm(prev => ({
      ...prev,
      [name]: value
    }));
  };

  // 🔹 検索履歴選択
  const handleHistorySelect = (keyword) => {
    setSearchForm(prev => ({
      ...prev,
      keyword
    }));
  };

  return (
    <div className="advanced-search-form">
      <h3>🔍 詳細検索</h3>
      
      <form onSubmit={handleSearch} className="search-form">
        {/* キーワード検索 */}
        <div className="search-field">
          <label htmlFor="keyword">キーワード</label>
          <div className="keyword-input-container">
            <input
              type="text"
              id="keyword"
              name="keyword"
              value={searchForm.keyword}
              onChange={handleInputChange}
              placeholder="エンティティ名や説明を検索..."
              className="form-input"
              disabled={isSearching}
            />
            
            {/* 検索履歴 */}
            {searchHistory.length > 0 && searchForm.keyword === '' && (
              <div className="search-history">
                <small>検索履歴:</small>
                <div className="history-tags">
                  {searchHistory.map((item, index) => (
                    <button
                      key={index}
                      type="button"
                      className="history-tag"
                      onClick={() => handleHistorySelect(item)}
                    >
                      {item}
                    </button>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>

        {/* フィルター条件 */}
        <div className="filter-row">
          <div className="filter-field">
            <label htmlFor="status">ステータス</label>
            <select
              id="status"
              name="status"
              value={searchForm.status}
              onChange={handleInputChange}
              className="form-select"
              disabled={isSearching}
            >
              <option value="">すべて</option>
              <option value="ACTIVE">アクティブ</option>
              <option value="INACTIVE">非アクティブ</option>
              <option value="ARCHIVED">アーカイブ</option>
            </select>
          </div>

          <div className="filter-field">
            <label htmlFor="userId">作成者ID</label>
            <input
              type="text"
              id="userId"
              name="userId"
              value={searchForm.userId}
              onChange={handleInputChange}
              placeholder="ユーザーID"
              className="form-input"
              disabled={isSearching}
            />
          </div>
        </div>

        {/* 日付範囲 */}
        <div className="date-range-row">
          <div className="date-field">
            <label htmlFor="createdDateFrom">作成日（開始）</label>
            <input
              type="date"
              id="createdDateFrom"
              name="createdDateFrom"
              value={searchForm.createdDateFrom}
              onChange={handleInputChange}
              className="form-input"
              disabled={isSearching}
            />
          </div>

          <div className="date-field">
            <label htmlFor="createdDateTo">作成日（終了）</label>
            <input
              type="date"
              id="createdDateTo"
              name="createdDateTo"
              value={searchForm.createdDateTo}
              onChange={handleInputChange}
              className="form-input"
              disabled={isSearching}
            />
          </div>
        </div>

        {/* ソート設定 */}
        <div className="sort-row">
          <div className="sort-field">
            <label htmlFor="sortBy">ソート項目</label>
            <select
              id="sortBy"
              name="sortBy"
              value={searchForm.sortBy}
              onChange={handleInputChange}
              className="form-select"
              disabled={isSearching}
            >
              <option value="createdAt">作成日</option>
              <option value="updatedAt">更新日</option>
              <option value="name">名前</option>
            </select>
          </div>

          <div className="sort-field">
            <label htmlFor="sortOrder">ソート順</label>
            <select
              id="sortOrder"
              name="sortOrder"
              value={searchForm.sortOrder}
              onChange={handleInputChange}
              className="form-select"
              disabled={isSearching}
            >
              <option value="desc">降順</option>
              <option value="asc">昇順</option>
            </select>
          </div>
        </div>

        {/* アクションボタン */}
        <div className="search-actions">
          <button
            type="button"
            onClick={handleReset}
            className="btn btn-secondary"
            disabled={isSearching}
          >
            リセット
          </button>
          
          <button
            type="submit"
            className="btn btn-primary"
            disabled={isSearching}
          >
            {isSearching ? (
              <>
                <span className="loading-spinner"></span>
                検索中...
              </>
            ) : (
              '🔍 検索'
            )}
          </button>
        </div>
      </form>
    </div>
  );
}

export default AdvancedSearchForm;
```

## 📊 バルク操作フォーム

```javascript
/**
 * 📊 バルク操作フォームコンポーネント
 * 複数のエンティティに対する一括操作
 */

import React, { useState } from 'react';
import { generateClient } from 'aws-amplify/api';
import { updateEntity, deleteEntity } from '../graphql/mutations';

const client = generateClient();

function BulkOperationForm({ selectedEntities, onOperationComplete, onCancel }) {
  const [operation, setOperation] = useState('');
  const [newStatus, setNewStatus] = useState('ACTIVE');
  const [isProcessing, setIsProcessing] = useState(false);
  const [progress, setProgress] = useState(0);
  const [errors, setErrors] = useState([]);

  // 🔹 バルク操作の実行
  const handleBulkOperation = async () => {
    if (!operation) {
      alert('操作を選択してください');
      return;
    }

    const confirmMessage = operation === 'delete' 
      ? `${selectedEntities.length}件のエンティティを削除しますか？この操作は取り消せません。`
      : `${selectedEntities.length}件のエンティティのステータスを「${newStatus}」に変更しますか？`;

    if (!window.confirm(confirmMessage)) {
      return;
    }

    setIsProcessing(true);
    setProgress(0);
    setErrors([]);

    const results = [];
    const operationErrors = [];

    try {
      for (let i = 0; i < selectedEntities.length; i++) {
        const entity = selectedEntities[i];
        
        try {
          let result;
          
          if (operation === 'delete') {
            result = await client.graphql({
              query: deleteEntity,
              variables: { id: entity.id }
            });
            results.push({ id: entity.id, success: true, operation: 'deleted' });
          } else if (operation === 'updateStatus') {
            result = await client.graphql({
              query: updateEntity,
              variables: {
                input: {
                  id: entity.id,
                  status: newStatus,
                  updatedAt: new Date().toISOString()
                }
              }
            });
            results.push({ id: entity.id, success: true, operation: 'updated', newStatus });
          }
          
        } catch (error) {
          console.error(`エンティティ ${entity.id} の操作でエラー:`, error);
          operationErrors.push({
            id: entity.id,
            name: entity.name,
            error: error.message
          });
        }

        // プログレス更新
        setProgress(Math.round(((i + 1) / selectedEntities.length) * 100));
        
        // UI応答性のための小さな遅延
        if (i < selectedEntities.length - 1) {
          await new Promise(resolve => setTimeout(resolve, 100));
        }
      }

      // 結果のまとめ
      const successCount = results.length;
      const errorCount = operationErrors.length;
      
      if (errorCount > 0) {
        setErrors(operationErrors);
      }

      // 操作完了通知
      onOperationComplete && onOperationComplete({
        operation,
        successCount,
        errorCount,
        results,
        errors: operationErrors
      });

    } catch (error) {
      console.error('バルク操作でエラー:', error);
      alert('操作中にエラーが発生しました');
    } finally {
      setIsProcessing(false);
    }
  };

  return (
    <div className="bulk-operation-form">
      <div className="form-header">
        <h3>📊 一括操作</h3>
        <p>{selectedEntities.length}件のエンティティが選択されています</p>
      </div>

      <div className="form-content">
        {/* 操作選択 */}
        <div className="operation-selection">
          <h4>実行する操作を選択</h4>
          
          <div className="operation-options">
            <label className="operation-option">
              <input
                type="radio"
                name="operation"
                value="updateStatus"
                checked={operation === 'updateStatus'}
                onChange={(e) => setOperation(e.target.value)}
                disabled={isProcessing}
              />
              <span className="option-label">
                🔄 ステータス一括変更
              </span>
            </label>

            <label className="operation-option">
              <input
                type="radio"
                name="operation"
                value="delete"
                checked={operation === 'delete'}
                onChange={(e) => setOperation(e.target.value)}
                disabled={isProcessing}
              />
              <span className="option-label danger">
                🗑️ 一括削除
              </span>
            </label>
          </div>
        </div>

        {/* ステータス変更の場合の追加設定 */}
        {operation === 'updateStatus' && (
          <div className="status-selection">
            <label htmlFor="newStatus">新しいステータス</label>
            <select
              id="newStatus"
              value={newStatus}
              onChange={(e) => setNewStatus(e.target.value)}
              className="form-select"
              disabled={isProcessing}
            >
              <option value="ACTIVE">🟢 アクティブ</option>
              <option value="INACTIVE">🔴 非アクティブ</option>
              <option value="ARCHIVED">📦 アーカイブ</option>
            </select>
          </div>
        )}

        {/* プログレス表示 */}
        {isProcessing && (
          <div className="operation-progress">
            <div className="progress-bar">
              <div 
                className="progress-fill"
                style={{ width: `${progress}%` }}
              ></div>
            </div>
            <p>処理中... {progress}% 完了</p>
          </div>
        )}

        {/* エラー表示 */}
        {errors.length > 0 && (
          <div className="operation-errors">
            <h4>⚠️ エラーが発生したアイテム</h4>
            <ul>
              {errors.map((error, index) => (
                <li key={index}>
                  <strong>{error.name}</strong> (ID: {error.id})<br />
                  エラー: {error.error}
                </li>
              ))}
            </ul>
          </div>
        )}

        {/* アクションボタン */}
        <div className="form-actions">
          <button
            type="button"
            onClick={onCancel}
            className="btn btn-secondary"
            disabled={isProcessing}
          >
            キャンセル
          </button>
          
          <button
            type="button"
            onClick={handleBulkOperation}
            className={`btn ${operation === 'delete' ? 'btn-danger' : 'btn-primary'}`}
            disabled={!operation || isProcessing}
          >
            {isProcessing ? (
              '処理中...'
            ) : (
              operation === 'delete' ? '🗑️ 削除実行' : '🔄 更新実行'
            )}
          </button>
        </div>
      </div>
    </div>
  );
}

export default BulkOperationForm;
```

## 🎯 使用方法

### 1. ファイルの配置
```
src/
├── components/
│   ├── forms/
│   │   ├── EntityForm.jsx              # 基本的な作成・編集フォーム
│   │   ├── AdvancedSearchForm.jsx      # 高度な検索フォーム
│   │   └── BulkOperationForm.jsx       # バルク操作フォーム
```

### 2. 使用例
```javascript
import React, { useState } from 'react';
import EntityForm from './forms/EntityForm';
import AdvancedSearchForm from './forms/AdvancedSearchForm';

function MyComponent() {
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [searchResults, setSearchResults] = useState([]);

  const handleFormSuccess = (entity, action) => {
    console.log(`エンティティが${action}されました:`, entity);
    setIsFormOpen(false);
    // リストの再読み込みなど
  };

  const handleSearchResults = (results, searchForm) => {
    setSearchResults(results);
    console.log('検索結果:', results.length, '件');
  };

  return (
    <div>
      {isFormOpen && (
        <EntityForm
          currentUser={currentUser}
          onSuccess={handleFormSuccess}
          onCancel={() => setIsFormOpen(false)}
        />
      )}
      
      <AdvancedSearchForm
        onSearchResults={handleSearchResults}
        onReset={() => setSearchResults([])}
      />
    </div>
  );
}
```

## 🔗 関連テンプレート

- [React GraphQL操作テンプレート](./react-graphql-template.md) - GraphQL操作の実装
- [React コンポーネントテンプレート](./react-components-template.md) - UIコンポーネントの実装
- [React スタイリングテンプレート](./react-styling-template.md) - フォームのスタイリング

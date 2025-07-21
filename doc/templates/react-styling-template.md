# 🎨 React スタイリングテンプレート

このファイルには、AWS AppSync チャットアプリのReactコンポーネント用の包括的なスタイリングテンプレートが含まれています。
モダンでレスポンシブなデザインシステムに基づいています。

## 🎨 基本CSSテンプレート

### エンティティコンポーネント用スタイル

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

.entity-title h3 {
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

.status-badge.status-active {
  background: #c6f6d5;
  color: #276749;
}

.status-badge.status-inactive {
  background: #fed7d7;
  color: #c53030;
}

.status-badge.status-unknown {
  background: #e2e8f0;
  color: #4a5568;
}

.card-description {
  padding: 0 1rem 1rem 1rem;
}

.card-description p {
  color: #718096;
  line-height: 1.5;
  margin: 0;
}

.card-description p.truncated {
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.expand-button {
  background: none;
  border: none;
  color: #4299e1;
  cursor: pointer;
  font-size: 0.875rem;
  margin-top: 0.5rem;
}

.card-metadata {
  padding: 0 1rem 1rem 1rem;
}

.metadata-item {
  display: flex;
  justify-content: space-between;
  margin-bottom: 0.25rem;
  font-size: 0.875rem;
}

.metadata-item .label {
  color: #718096;
}

.metadata-item .value {
  color: #2d3748;
  font-weight: 500;
}

.related-items {
  padding: 0 1rem 1rem 1rem;
  border-top: 1px solid #f7fafc;
  margin-top: 1rem;
  padding-top: 1rem;
}

.related-items h4 {
  font-size: 0.875rem;
  font-weight: 600;
  color: #4a5568;
  margin: 0 0 0.5rem 0;
}

.related-items ul {
  list-style: none;
  padding: 0;
  margin: 0;
}

.related-items li {
  display: flex;
  justify-content: space-between;
  padding: 0.25rem 0;
  font-size: 0.75rem;
  color: #718096;
}

.more-items {
  font-size: 0.75rem;
  color: #4299e1;
  margin: 0.5rem 0 0 0;
}

/* 🔹 アクションメニュー */
.action-menu {
  position: relative;
}

.menu-trigger {
  background: none;
  border: none;
  font-size: 1.5rem;
  color: #718096;
  cursor: pointer;
  padding: 0.25rem;
  border-radius: 4px;
  transition: background-color 0.2s;
}

.menu-trigger:hover {
  background: #f7fafc;
}

.menu-dropdown {
  position: absolute;
  top: 100%;
  right: 0;
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  z-index: 10;
  min-width: 150px;
}

.menu-item {
  display: block;
  width: 100%;
  padding: 0.75rem 1rem;
  border: none;
  background: none;
  text-align: left;
  font-size: 0.875rem;
  cursor: pointer;
  transition: background-color 0.2s;
}

.menu-item:hover {
  background: #f7fafc;
}

.menu-item.danger {
  color: #e53e3e;
}

.menu-item.danger:hover {
  background: #fed7d7;
}
```

### フォーム用スタイル

```css
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
  font-family: inherit;
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

/* 🔹 検索フォーム */
.advanced-search-form {
  background: white;
  border-radius: 12px;
  padding: 1.5rem;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  margin-bottom: 2rem;
}

.search-form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.search-field {
  display: flex;
  flex-direction: column;
}

.keyword-input-container {
  position: relative;
}

.search-history {
  margin-top: 0.5rem;
}

.history-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  margin-top: 0.25rem;
}

.history-tag {
  background: #e2e8f0;
  border: none;
  border-radius: 16px;
  padding: 0.25rem 0.75rem;
  font-size: 0.75rem;
  cursor: pointer;
  transition: background-color 0.2s;
}

.history-tag:hover {
  background: #cbd5e0;
}

.filter-row,
.date-range-row,
.sort-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
}

.filter-field,
.date-field,
.sort-field {
  display: flex;
  flex-direction: column;
}

.search-actions {
  display: flex;
  gap: 1rem;
  justify-content: flex-end;
  margin-top: 1rem;
}

/* 🔹 バルク操作フォーム */
.bulk-operation-form {
  background: white;
  border-radius: 12px;
  padding: 1.5rem;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}

.operation-selection {
  margin-bottom: 1.5rem;
}

.operation-options {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  margin-top: 1rem;
}

.operation-option {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem;
  border: 2px solid #e2e8f0;
  border-radius: 8px;
  cursor: pointer;
  transition: border-color 0.2s;
}

.operation-option:hover {
  border-color: #cbd5e0;
}

.operation-option input[type="radio"]:checked + .option-label {
  font-weight: 600;
}

.option-label.danger {
  color: #e53e3e;
}

.status-selection {
  margin-bottom: 1.5rem;
}

.operation-progress {
  margin: 1.5rem 0;
  padding: 1rem;
  background: #f7fafc;
  border-radius: 8px;
}

.progress-bar {
  width: 100%;
  height: 8px;
  background: #e2e8f0;
  border-radius: 4px;
  overflow: hidden;
  margin-bottom: 0.5rem;
}

.progress-fill {
  height: 100%;
  background: #4299e1;
  transition: width 0.3s ease;
}

.operation-errors {
  background: #fed7d7;
  border: 1px solid #feb2b2;
  border-radius: 8px;
  padding: 1rem;
  margin: 1rem 0;
}

.operation-errors h4 {
  color: #c53030;
  margin: 0 0 1rem 0;
}

.operation-errors ul {
  margin: 0;
  color: #742a2a;
}
```

### ボタンとインタラクション

```css
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
  text-decoration: none;
  font-family: inherit;
}

.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  transform: none;
}

.btn-primary {
  background: #4299e1;
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background: #3182ce;
  transform: translateY(-1px);
  box-shadow: 0 4px 8px rgba(66, 153, 225, 0.3);
}

.btn-secondary {
  background: #e2e8f0;
  color: #4a5568;
}

.btn-secondary:hover:not(:disabled) {
  background: #cbd5e0;
  transform: translateY(-1px);
}

.btn-danger {
  background: #e53e3e;
  color: white;
}

.btn-danger:hover:not(:disabled) {
  background: #c53030;
  transform: translateY(-1px);
  box-shadow: 0 4px 8px rgba(229, 62, 62, 0.3);
}

.btn-success {
  background: #38a169;
  color: white;
}

.btn-success:hover:not(:disabled) {
  background: #2f855a;
  transform: translateY(-1px);
  box-shadow: 0 4px 8px rgba(56, 161, 105, 0.3);
}

.btn-outline {
  background: transparent;
  border: 2px solid #4299e1;
  color: #4299e1;
}

.btn-outline:hover:not(:disabled) {
  background: #4299e1;
  color: white;
}

/* 🔹 ローディング・ステートコンポーネント */
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

.loading-progress {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 2rem;
  text-align: center;
}

.progress-container {
  width: 100%;
  max-width: 400px;
}

.progress-message {
  margin-bottom: 1rem;
  font-weight: 500;
  color: #4a5568;
}

.progress-text {
  margin-top: 0.5rem;
  font-size: 0.875rem;
  color: #718096;
}

/* 🔹 空状態とエラー表示 */
.empty-state {
  text-align: center;
  padding: 3rem 1rem;
  color: #718096;
}

.empty-state p {
  margin: 0.5rem 0;
  font-size: 1rem;
}

.error-message {
  background: white;
  border: 1px solid #feb2b2;
  border-radius: 12px;
  padding: 1.5rem;
  text-align: center;
  max-width: 500px;
  margin: 2rem auto;
}

.message-header {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  margin-bottom: 1rem;
}

.message-icon {
  font-size: 1.5rem;
}

.message-title {
  margin: 0;
  font-size: 1.125rem;
  font-weight: 600;
  color: #2d3748;
}

.message-text {
  margin: 0 0 1rem 0;
  color: #4a5568;
  line-height: 1.5;
}

.message-warning {
  background: #fffaf0;
  border-color: #fbd38d;
}

.message-warning .message-title {
  color: #c05621;
}

.message-warning .message-text {
  color: #9c4221;
}

.message-info {
  background: #ebf8ff;
  border-color: #90cdf4;
}

.message-info .message-title {
  color: #2c5282;
}

.message-info .message-text {
  color: #2a69ac;
}

.message-error {
  background: #fff5f5;
  border-color: #feb2b2;
}

.message-error .message-title {
  color: #c53030;
}

.message-error .message-text {
  color: #742a2a;
}

.error-details {
  margin-top: 1rem;
  text-align: left;
}

.error-details summary {
  cursor: pointer;
  font-weight: 500;
  margin-bottom: 0.5rem;
}

.error-details pre {
  background: #f7fafc;
  padding: 1rem;
  border-radius: 4px;
  font-size: 0.75rem;
  overflow-x: auto;
  margin: 0.5rem 0;
}

.message-actions {
  margin-top: 1rem;
}

.retry-button {
  background: #4299e1;
  color: white;
  border: none;
  border-radius: 6px;
  padding: 0.5rem 1rem;
  font-size: 0.875rem;
  cursor: pointer;
  transition: background-color 0.2s;
}

.retry-button:hover {
  background: #3182ce;
}

/* 🔹 エラー境界 */
.error-boundary {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 400px;
  padding: 2rem;
}

.error-content {
  text-align: center;
  max-width: 500px;
}

.error-content h2 {
  color: #c53030;
  margin-bottom: 1rem;
}

.error-actions {
  display: flex;
  gap: 1rem;
  justify-content: center;
  margin-top: 1.5rem;
}

.reload-button {
  background: #e2e8f0;
  color: #4a5568;
  border: none;
  border-radius: 6px;
  padding: 0.5rem 1rem;
  font-size: 0.875rem;
  cursor: pointer;
  transition: background-color 0.2s;
}

.reload-button:hover {
  background: #cbd5e0;
}
```

### レスポンシブデザイン

```css
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
  
  .filter-row,
  .date-range-row,
  .sort-row {
    grid-template-columns: 1fr;
  }
  
  .operation-options {
    gap: 0.5rem;
  }
  
  .search-actions {
    flex-direction: column;
  }
}

@media (max-width: 480px) {
  .stats-grid {
    grid-template-columns: 1fr;
  }
  
  .entity-list {
    padding: 0.5rem;
  }
  
  .form-content {
    padding: 1rem;
  }
  
  .card-header {
    flex-direction: column;
    align-items: stretch;
    gap: 0.5rem;
  }
  
  .entity-title {
    margin-bottom: 0.5rem;
  }
}

/* 🔹 アクセシビリティ */
@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}

@media (prefers-color-scheme: dark) {
  /* ダークモード対応の場合 */
  .entity-card {
    background: #2d3748;
    border-color: #4a5568;
    color: #e2e8f0;
  }
  
  .form-input,
  .form-textarea,
  .form-select {
    background: #2d3748;
    border-color: #4a5568;
    color: #e2e8f0;
  }
  
  .form-input:focus,
  .form-textarea:focus,
  .form-select:focus {
    border-color: #63b3ed;
  }
}

/* 🔹 高コントラストモード */
@media (prefers-contrast: high) {
  .btn {
    border: 2px solid currentColor;
  }
  
  .entity-card {
    border-width: 2px;
  }
  
  .form-input,
  .form-textarea,
  .form-select {
    border-width: 2px;
  }
}
```

## 🎨 UIパターンとコンポーネント

### カードレイアウトパターン

```css
/* カード基本パターン */
.card-pattern-basic {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 1rem;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.card-pattern-elevated {
  background: white;
  border: none;
  border-radius: 12px;
  padding: 1.5rem;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.card-pattern-outlined {
  background: white;
  border: 2px solid #e2e8f0;
  border-radius: 8px;
  padding: 1rem;
  box-shadow: none;
}

.card-pattern-gradient {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border: none;
  border-radius: 12px;
  padding: 1.5rem;
  color: white;
}
```

### グリッドレイアウトパターン

```css
/* レスポンシブグリッドパターン */
.grid-auto-fit {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 1rem;
}

.grid-auto-fill {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
  gap: 1rem;
}

.grid-responsive {
  display: grid;
  grid-template-columns: 1fr;
  gap: 1rem;
}

@media (min-width: 640px) {
  .grid-responsive {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (min-width: 1024px) {
  .grid-responsive {
    grid-template-columns: repeat(3, 1fr);
  }
}
```

## 🎯 使用方法

### 1. スタイルファイルの組織化
```
src/
├── styles/
│   ├── globals.css          # グローバルスタイル
│   ├── components.css       # コンポーネント固有スタイル
│   ├── forms.css           # フォーム関連スタイル
│   ├── utilities.css       # ユーティリティクラス
│   └── responsive.css      # レスポンシブ対応
```

### 2. CSSの読み込み
```javascript
// main.jsx または App.jsx
import './styles/globals.css';
import './styles/components.css';
import './styles/forms.css';
import './styles/utilities.css';
import './styles/responsive.css';
```

### 3. CSS Variables（カスタムプロパティ）の活用
```css
:root {
  --primary-color: #4299e1;
  --secondary-color: #718096;
  --success-color: #38a169;
  --warning-color: #ed8936;
  --error-color: #e53e3e;
  
  --border-radius: 8px;
  --border-radius-lg: 12px;
  --shadow-sm: 0 2px 4px rgba(0, 0, 0, 0.1);
  --shadow-md: 0 4px 12px rgba(0, 0, 0, 0.1);
  
  --font-size-sm: 0.875rem;
  --font-size-base: 1rem;
  --font-size-lg: 1.125rem;
  --font-size-xl: 1.25rem;
  
  --spacing-xs: 0.25rem;
  --spacing-sm: 0.5rem;
  --spacing-md: 1rem;
  --spacing-lg: 1.5rem;
  --spacing-xl: 2rem;
}
```

## 🔗 関連テンプレート

- [React GraphQL操作テンプレート](./react-graphql-template.md) - GraphQL操作の実装
- [React コンポーネントテンプレート](./react-components-template.md) - UIコンポーネントの実装
- [React フォームテンプレート](./react-forms-template.md) - フォーム処理の実装

# 📚 テンプレート集

このディレクトリには、AWS AppSync チャットアプリ開発で使用する各種テンプレートファイルが含まれています。
テンプレートは機能別に分割され、必要な部分だけを参照できるように整理されています。

## 📁 テンプレートファイル一覧

### 🔗 GraphQL関連
- [`graphql-schema-template.md`](./graphql-schema-template.md) - GraphQLスキーマ定義のテンプレート

### 🧠 JavaScript リゾルバー関連
- [`javascript-resolver-basic-template.md`](./javascript-resolver-basic-template.md) - 基本的なCRUD操作リゾルバー
- [`javascript-resolver-advanced-template.md`](./javascript-resolver-advanced-template.md) - 高度なクエリ・検索・統計リゾルバー
- [`javascript-resolver-template.md`](./javascript-resolver-template.md) - 完全版リゾルバーテンプレート（参考用）

### ⚛️ React フロントエンド関連
- [`react-graphql-template.md`](./react-graphql-template.md) - GraphQL操作（クエリ・ミューテーション・サブスクリプション）
- [`react-components-template.md`](./react-components-template.md) - UIコンポーネント（一覧・カード・エラー境界など）
- [`react-forms-template.md`](./react-forms-template.md) - フォーム関連（作成・編集・検索・バルク操作）
- [`react-styling-template.md`](./react-styling-template.md) - CSS・スタイリング・レスポンシブデザイン
- [`react-frontend-template.md`](./react-frontend-template.md) - 完全版フロントエンドテンプレート（参考用）

### 🏗️ Terraform関連
- [`terraform-template.md`](./terraform-template.md) - AWS インフラ構築用 Terraform テンプレート

## 🎯 使用ガイド

### 🔰 初心者向け
1. **基本的なCRUD操作**: [`javascript-resolver-basic-template.md`](./javascript-resolver-basic-template.md)
2. **シンプルなReactコンポーネント**: [`react-components-template.md`](./react-components-template.md)
3. **基本的なスタイリング**: [`react-styling-template.md`](./react-styling-template.md)

### 🚀 中級者向け
1. **GraphQL操作の実装**: [`react-graphql-template.md`](./react-graphql-template.md)
2. **高度なクエリ**: [`javascript-resolver-advanced-template.md`](./javascript-resolver-advanced-template.md)
3. **フォーム処理**: [`react-forms-template.md`](./react-forms-template.md)

### 🎯 上級者向け
1. **完全版テンプレート**: 各 `*-template.md` ファイル
2. **カスタマイズとパフォーマンス最適化**
3. **複合的な機能実装**

## 📝 テンプレート使用方法

### 1. 必要な部分をコピー
各テンプレートから必要な部分をコピーして、自分のプロジェクトに適用してください。

### 2. プロジェクトに合わせて修正
- エンティティ名を自分の機能に合わせて変更
- フィールド名やバリデーションルールを調整
- スタイリングをプロジェクトのデザインシステムに合わせて修正

### 3. 段階的実装
- 基本機能から始めて、徐々に高度な機能を追加
- 各段階でテストを行い、動作確認を実施

## 🔗 関連ドキュメント

- [API追加ガイド](../08-api-basics.md) - テンプレートを使った新機能の追加方法
- [デプロイ・運用ガイド](../10-deployment-guide.md) - テンプレートを使った機能のデプロイ方法

## 💡 Tips

### テンプレートのカスタマイズ例
```javascript
// テンプレートの「Entity」を「Room」に置き換える例
// Before: createEntity
// After:  createRoom

// Before: EntityList
// After:  RoomList
```

### よく使われる組み合わせ
1. **基本的なCRUD画面**: 
   - `react-graphql-template.md` (GraphQL操作)
   - `react-components-template.md` (一覧・カード)
   - `react-forms-template.md` (作成・編集フォーム)

2. **検索機能付きの画面**:
   - `javascript-resolver-advanced-template.md` (検索リゾルバー)
   - `react-forms-template.md` (検索フォーム)
   - `react-components-template.md` (結果表示)

3. **統計ダッシュボード**:
   - `javascript-resolver-advanced-template.md` (統計リゾルバー)
   - `react-components-template.md` (統計表示コンポーネント)
   - `react-styling-template.md` (グラフ・チャート用CSS)

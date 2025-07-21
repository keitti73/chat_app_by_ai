# 📝 GraphQLスキーマテンプレート

このファイルには、新しいAPI機能を追加する際のGraphQLスキーマテンプレートが含まれています。

## 🎯 基本的なCRUD操作テンプレート

### Type定義テンプレート

```graphql
# 🔹 基本的なエンティティ型の定義
type YourEntityName {
    id: ID!                      # 必須：一意識別子
    createdAt: String!           # 必須：作成日時
    updatedAt: String            # 任意：更新日時
    
    # 🔽 ここに独自のフィールドを追加
    name: String!                # 例：名前（必須）
    description: String          # 例：説明（任意）
    status: EntityStatus         # 例：ステータス（Enum）
    userId: String!              # 例：所有者ID（必須）
    
    # 🔽 関連データ（他のエンティティとの関係）
    owner: User                  # 例：所有者情報
    items: [RelatedItem]         # 例：関連アイテム一覧
    itemCount: Int               # 例：関連アイテム数
}

# 🔹 Enum型の定義（ステータスなどの固定値）
enum EntityStatus {
    ACTIVE                       # アクティブ
    INACTIVE                     # 非アクティブ
    PENDING                      # 保留中
    DELETED                      # 削除済み
}

# 🔹 入力型の定義（ミューテーション用）
input CreateEntityInput {
    name: String!                # 必須フィールド
    description: String          # 任意フィールド
    status: EntityStatus = ACTIVE # デフォルト値付き
    userId: String!              # 関連ユーザーID
}

input UpdateEntityInput {
    id: ID!                      # 更新対象のID（必須）
    name: String                 # 任意：更新する場合のみ
    description: String          # 任意：更新する場合のみ
    status: EntityStatus         # 任意：更新する場合のみ
}
```

### Query定義テンプレート

```graphql
# 既存のQueryタイプに以下を追加
type Query {
    # ... 既存のクエリ
    
    # 🔹 単一アイテム取得
    getEntity(id: ID!): YourEntityName
    
    # 🔹 一覧取得（全件）
    listEntities: [YourEntityName]
    
    # 🔹 条件付き一覧取得
    listEntitiesByUser(userId: String!): [YourEntityName]
    listEntitiesByStatus(status: EntityStatus!): [YourEntityName]
    
    # 🔹 ページング付き一覧取得
    listEntitiesPaginated(
        limit: Int = 20           # デフォルト20件
        nextToken: String         # 次ページのトークン
        filter: EntityFilter      # フィルタ条件
    ): EntityConnection
    
    # 🔹 検索クエリ
    searchEntities(
        keyword: String!          # 検索キーワード
        limit: Int = 10           # 結果件数制限
    ): [YourEntityName]
    
    # 🔹 統計・集計クエリ
    getEntityStats(userId: String): EntityStats
}

# 🔹 ページング用の型定義
type EntityConnection {
    items: [YourEntityName]      # 実際のデータ
    nextToken: String            # 次ページトークン
    total: Int                   # 総件数
}

# 🔹 フィルタ用の入力型
input EntityFilter {
    status: EntityStatus         # ステータスで絞り込み
    createdAfter: String         # 作成日時以降で絞り込み
    createdBefore: String        # 作成日時以前で絞り込み
    userId: String               # ユーザーで絞り込み
}

# 🔹 統計用の型定義
type EntityStats {
    total: Int!                  # 総数
    activeCount: Int!            # アクティブ数
    inactiveCount: Int!          # 非アクティブ数
    todayCreated: Int!           # 今日作成された数
    recentItems: [YourEntityName] # 最近の項目
}
```

### Mutation定義テンプレート

```graphql
# 既存のMutationタイプに以下を追加
type Mutation {
    # ... 既存のミューテーション
    
    # 🔹 作成（Create）
    createEntity(input: CreateEntityInput!): YourEntityName
    
    # 🔹 更新（Update）
    updateEntity(input: UpdateEntityInput!): YourEntityName
    
    # 🔹 削除（Delete）
    deleteEntity(id: ID!): YourEntityName
    
    # 🔹 一括操作
    createMultipleEntities(inputs: [CreateEntityInput!]!): [YourEntityName]
    deleteMultipleEntities(ids: [ID!]!): [YourEntityName]
    
    # 🔹 ステータス変更（特別な操作）
    activateEntity(id: ID!): YourEntityName
    deactivateEntity(id: ID!): YourEntityName
    
    # 🔹 関連付け操作
    addEntityToUser(entityId: ID!, userId: String!): YourEntityName
    removeEntityFromUser(entityId: ID!, userId: String!): YourEntityName
}
```

### Subscription定義テンプレート

```graphql
# 既存のSubscriptionタイプに以下を追加
type Subscription {
    # ... 既存のサブスクリプション
    
    # 🔹 作成イベント
    onEntityCreated(userId: String): YourEntityName
        @aws_subscribe(mutations: ["createEntity"])
    
    # 🔹 更新イベント
    onEntityUpdated(entityId: ID): YourEntityName
        @aws_subscribe(mutations: ["updateEntity", "activateEntity", "deactivateEntity"])
    
    # 🔹 削除イベント
    onEntityDeleted(userId: String): YourEntityName
        @aws_subscribe(mutations: ["deleteEntity"])
    
    # 🔹 ステータス変更イベント
    onEntityStatusChanged(entityId: ID): YourEntityName
        @aws_subscribe(mutations: ["activateEntity", "deactivateEntity"])
    
    # 🔹 ユーザー固有のイベント
    onUserEntityChanged(userId: String!): YourEntityName
        @aws_subscribe(mutations: [
            "createEntity", 
            "updateEntity", 
            "deleteEntity",
            "addEntityToUser",
            "removeEntityFromUser"
        ])
}
```

## 🎯 特殊なパターンテンプレート

### リレーション（多対多）テンプレート

```graphql
# 🔹 中間テーブル型の定義
type EntityRelation {
    id: ID!                      # 関連ID
    entityAId: ID!               # エンティティA のID
    entityBId: ID!               # エンティティB のID
    relationType: RelationType!  # 関連の種類
    createdAt: String!           # 関連作成日時
    metadata: String             # 関連に関する追加情報
    
    # 関連先の実体
    entityA: YourEntityName
    entityB: AnotherEntityName
}

enum RelationType {
    PARENT_CHILD                 # 親子関係
    RELATED                      # 関連
    DEPENDENCY                   # 依存関係
    REFERENCE                    # 参照
}

# 関連操作のミューテーション
type Mutation {
    # 関連を作成
    createRelation(
        entityAId: ID!
        entityBId: ID!
        relationType: RelationType!
        metadata: String
    ): EntityRelation
    
    # 関連を削除
    removeRelation(
        entityAId: ID!
        entityBId: ID!
        relationType: RelationType
    ): EntityRelation
}

# 関連取得のクエリ
type Query {
    # 特定エンティティの関連一覧
    getEntityRelations(entityId: ID!): [EntityRelation]
    
    # 特定の関連タイプで検索
    getRelationsByType(
        entityId: ID!
        relationType: RelationType!
    ): [EntityRelation]
}
```

### 階層構造テンプレート

```graphql
# 🔹 階層構造を持つエンティティ
type HierarchicalEntity {
    id: ID!
    name: String!
    parentId: ID                 # 親エンティティのID
    level: Int!                  # 階層レベル（0が最上位）
    path: String!                # 階層パス（例："/root/child1/grandchild"）
    
    # 階層関係のデータ
    parent: HierarchicalEntity  # 親エンティティ
    children: [HierarchicalEntity] # 子エンティティ一覧
    ancestors: [HierarchicalEntity] # 祖先エンティティ一覧
    descendants: [HierarchicalEntity] # 子孫エンティティ一覧
    
    # 統計情報
    childrenCount: Int!          # 直接の子の数
    descendantsCount: Int!       # すべての子孫の数
    isLeaf: Boolean!             # 葉ノード（子がない）かどうか
    isRoot: Boolean!             # ルートノード（親がない）かどうか
}

type Query {
    # ルートノード一覧を取得
    getRootEntities: [HierarchicalEntity]
    
    # 特定ノードの子一覧を取得
    getChildEntities(parentId: ID!): [HierarchicalEntity]
    
    # 特定ノードの全祖先を取得
    getAncestors(entityId: ID!): [HierarchicalEntity]
    
    # 特定ノードの全子孫を取得
    getDescendants(entityId: ID!): [HierarchicalEntity]
    
    # 階層ツリー全体を取得
    getEntityTree(rootId: ID): [HierarchicalEntity]
}

type Mutation {
    # ノードを移動（親を変更）
    moveEntity(entityId: ID!, newParentId: ID): HierarchicalEntity
    
    # ノードをルートに移動
    moveToRoot(entityId: ID!): HierarchicalEntity
}
```

### ファイル・添付機能テンプレート

```graphql
# 🔹 ファイル・添付機能
type Attachment {
    id: ID!
    fileName: String!            # ファイル名
    fileSize: Int!               # ファイルサイズ（バイト）
    contentType: String!         # MIMEタイプ
    uploadUrl: String            # アップロード用URL（署名付き）
    downloadUrl: String          # ダウンロード用URL（署名付き）
    thumbnailUrl: String         # サムネイル画像URL
    
    # メタデータ
    uploadedBy: String!          # アップロードしたユーザーID
    uploadedAt: String!          # アップロード日時
    entityId: ID                 # 関連エンティティのID
    entityType: String           # 関連エンティティのタイプ
    
    # ファイル情報
    isImage: Boolean!            # 画像ファイルかどうか
    isVideo: Boolean!            # 動画ファイルかどうか
    isDocument: Boolean!         # 文書ファイルかどうか
    
    # 画像・動画の場合の追加情報
    width: Int                   # 横幅（ピクセル）
    height: Int                  # 高さ（ピクセル）
    duration: Int                # 再生時間（秒、動画の場合）
}

type Query {
    # エンティティに紐づく添付ファイル一覧
    getAttachments(entityId: ID!, entityType: String!): [Attachment]
    
    # ファイルアップロード用の署名付きURL取得
    getUploadUrl(
        fileName: String!
        contentType: String!
        entityId: ID
        entityType: String
    ): UploadInfo
}

type UploadInfo {
    uploadUrl: String!           # アップロード先URL
    downloadUrl: String!         # ダウンロード用URL
    attachmentId: ID!            # 作成された添付ファイルID
}

type Mutation {
    # 添付ファイル情報を作成
    createAttachment(
        fileName: String!
        fileSize: Int!
        contentType: String!
        entityId: ID
        entityType: String
    ): Attachment
    
    # 添付ファイルを削除
    deleteAttachment(id: ID!): Attachment
    
    # 添付ファイルを別のエンティティに移動
    moveAttachment(
        attachmentId: ID!
        newEntityId: ID!
        newEntityType: String!
    ): Attachment
}

type Subscription {
    # 添付ファイルのアップロード完了通知
    onAttachmentUploaded(entityId: ID): Attachment
        @aws_subscribe(mutations: ["createAttachment"])
    
    # 添付ファイルの削除通知
    onAttachmentDeleted(entityId: ID): Attachment
        @aws_subscribe(mutations: ["deleteAttachment"])
}
```

## 📋 使用方法

1. **適切なテンプレートを選択**
   - 基本的なCRUD操作：基本テンプレートを使用
   - 関連データがある場合：リレーションテンプレートを追加
   - 階層構造が必要：階層構造テンプレートを使用
   - ファイル機能が必要：ファイルテンプレートを追加

2. **カスタマイズ**
   - `YourEntityName` を実際のエンティティ名に変更
   - フィールドを追加・削除・修正
   - Enumの値を実際の用途に合わせて修正

3. **既存スキーマとの統合**
   - 既存の `schema.graphql` に追記
   - 型名や フィールド名の重複に注意
   - 一貫性のある命名規則を維持

---

**💡 このテンプレートをベースに、プロジェクトに必要な機能を効率的に実装できます！**

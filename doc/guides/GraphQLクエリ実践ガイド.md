# 🎯 GraphQLクエリ実践ガイド

## 📖 概要

このガイドでは、チャットアプリで実際に使用するGraphQLクエリの書き方と実行方法を、実用的な例とともに解説します。

## 🔧 事前準備

### GraphQLクライアントの設定

```javascript
// src/graphql/client.js
import { generateClient } from 'aws-amplify/api';

const client = generateClient();

// 使用例
const result = await client.graphql({
  query: myQuery,
  variables: { id: 'room123' }
});
```

## 📊 Query実践例（データ取得）

### 1. 基本的なルーム一覧取得

**目的**: 自分が作成したルームの一覧を表示

```graphql
query GetMyOwnedRooms {
  myOwnedRooms {
    id
    name
    owner
    createdAt
  }
}
```

**JavaScript実装例**:
```javascript
import { graphql } from 'aws-amplify/api';

const getMyOwnedRooms = `
  query GetMyOwnedRooms {
    myOwnedRooms {
      id
      name
      owner
      createdAt
    }
  }
`;

const fetchMyRooms = async () => {
  try {
    const result = await graphql({ query: getMyOwnedRooms });
    console.log('私のルーム一覧:', result.data.myOwnedRooms);
    return result.data.myOwnedRooms;
  } catch (error) {
    console.error('ルーム取得エラー:', error);
  }
};
```

**期待される結果**:
```json
{
  "data": {
    "myOwnedRooms": [
      {
        "id": "01234567-89ab-cdef-0123-456789abcdef",
        "name": "開発チーム雑談",
        "owner": "user123",
        "createdAt": "2024-01-15T10:30:00.000Z"
      }
    ]
  }
}
```

### 2. パイプラインリゾルバーの活用

**目的**: 参加中のルーム一覧（高効率取得）

```graphql
query GetMyActiveRooms {
  myActiveRooms {
    id
    name
    owner
    createdAt
  }
}
```

**実装のポイント**:
- パイプラインリゾルバーが内部でN+1問題を解決
- フロントエンドは通常のQueryと同じ書き方
- 背後で複雑な最適化が自動実行

```javascript
const getMyActiveRooms = `
  query GetMyActiveRooms {
    myActiveRooms {
      id
      name
      owner
      createdAt
    }
  }
`;

const fetchActiveRooms = async () => {
  const result = await graphql({ query: getMyActiveRooms });
  return result.data.myActiveRooms;
};
```

### 3. 変数を使った動的クエリ

**目的**: 特定ルームのメッセージ取得（ページング対応）

```graphql
query GetMessages($roomId: ID!, $limit: Int) {
  listMessages(roomId: $roomId, limit: $limit) {
    id
    text
    user
    createdAt
    roomId
  }
}
```

**JavaScript実装例**:
```javascript
const getMessages = `
  query GetMessages($roomId: ID!, $limit: Int) {
    listMessages(roomId: $roomId, limit: $limit) {
      id
      text
      user
      createdAt
      roomId
    }
  }
`;

const fetchMessages = async (roomId, limit = 50) => {
  try {
    const result = await graphql({
      query: getMessages,
      variables: { roomId, limit }
    });
    
    // 時系列順にソート（最新が上）
    const messages = result.data.listMessages.sort(
      (a, b) => new Date(b.createdAt) - new Date(a.createdAt)
    );
    
    return messages;
  } catch (error) {
    console.error('メッセージ取得エラー:', error);
    return [];
  }
};

// 使用例
const messages = await fetchMessages('room-123', 20);
console.log('最新20件のメッセージ:', messages);
```

### 4. ネストしたデータの取得

**目的**: ルーム情報とメッセージを一度に取得

```graphql
query GetRoomWithMessages($id: ID!) {
  getRoom(id: $id) {
    id
    name
    owner
    createdAt
    messages {
      id
      text
      user
      createdAt
    }
  }
}
```

**実装のポイント**:
```javascript
const getRoomWithMessages = `
  query GetRoomWithMessages($id: ID!) {
    getRoom(id: $id) {
      id
      name
      owner
      createdAt
      messages {
        id
        text
        user
        createdAt
      }
    }
  }
`;

const fetchRoomWithMessages = async (roomId) => {
  const result = await graphql({
    query: getRoomWithMessages,
    variables: { id: roomId }
  });
  
  const room = result.data.getRoom;
  return {
    ...room,
    messages: room.messages.sort(
      (a, b) => new Date(a.createdAt) - new Date(b.createdAt)
    )
  };
};
```

## ✏️ Mutation実践例（データ変更）

### 1. ルーム作成

**目的**: 新しいチャットルームを作成

```graphql
mutation CreateRoom($name: String!) {
  createRoom(name: $name) {
    id
    name
    owner
    createdAt
  }
}
```

**React実装例**:
```javascript
import { useState } from 'react';
import { graphql } from 'aws-amplify/api';

const createRoom = `
  mutation CreateRoom($name: String!) {
    createRoom(name: $name) {
      id
      name
      owner
      createdAt
    }
  }
`;

const CreateRoomForm = () => {
  const [roomName, setRoomName] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleCreateRoom = async (e) => {
    e.preventDefault();
    
    if (!roomName.trim()) {
      alert('ルーム名を入力してください');
      return;
    }

    setIsLoading(true);
    try {
      const result = await graphql({
        query: createRoom,
        variables: { name: roomName.trim() }
      });
      
      console.log('ルーム作成成功:', result.data.createRoom);
      setRoomName(''); // フォームリセット
      
      // 成功時の処理（画面遷移など）
      // navigate(`/room/${result.data.createRoom.id}`);
      
    } catch (error) {
      console.error('ルーム作成エラー:', error);
      alert('ルーム作成に失敗しました');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <form onSubmit={handleCreateRoom}>
      <input
        type="text"
        value={roomName}
        onChange={(e) => setRoomName(e.target.value)}
        placeholder="ルーム名を入力"
        maxLength={50}
        disabled={isLoading}
      />
      <button type="submit" disabled={isLoading || !roomName.trim()}>
        {isLoading ? '作成中...' : 'ルーム作成'}
      </button>
    </form>
  );
};
```

### 2. メッセージ投稿

**目的**: チャットルームにメッセージを送信

```graphql
mutation PostMessage($roomId: ID!, $text: String!) {
  postMessage(roomId: $roomId, text: $text) {
    id
    text
    user
    createdAt
    roomId
  }
}
```

**React実装例**:
```javascript
const postMessage = `
  mutation PostMessage($roomId: ID!, $text: String!) {
    postMessage(roomId: $roomId, text: $text) {
      id
      text
      user
      createdAt
      roomId
    }
  }
`;

const MessageForm = ({ roomId }) => {
  const [messageText, setMessageText] = useState('');
  const [isSending, setIsSending] = useState(false);

  const handleSendMessage = async (e) => {
    e.preventDefault();
    
    if (!messageText.trim()) return;

    setIsSending(true);
    try {
      const result = await graphql({
        query: postMessage,
        variables: { 
          roomId: roomId,
          text: messageText.trim()
        }
      });
      
      console.log('メッセージ送信成功:', result.data.postMessage);
      setMessageText(''); // フォームリセット
      
    } catch (error) {
      console.error('メッセージ送信エラー:', error);
      alert('メッセージの送信に失敗しました');
    } finally {
      setIsSending(false);
    }
  };

  return (
    <form onSubmit={handleSendMessage}>
      <input
        type="text"
        value={messageText}
        onChange={(e) => setMessageText(e.target.value)}
        placeholder="メッセージを入力..."
        maxLength={1000}
        disabled={isSending}
        onKeyDown={(e) => {
          if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            handleSendMessage(e);
          }
        }}
      />
      <button type="submit" disabled={isSending || !messageText.trim()}>
        {isSending ? '送信中...' : '送信'}
      </button>
    </form>
  );
};
```

## 🔔 Subscription実践例（リアルタイム通知）

### 1. 新着メッセージの購読

**目的**: 特定ルームの新着メッセージをリアルタイム受信

```graphql
subscription OnMessagePosted($roomId: ID!) {
  onMessagePosted(roomId: $roomId) {
    id
    text
    user
    createdAt
    roomId
  }
}
```

**React実装例**:
```javascript
import { useEffect, useState } from 'react';
import { graphql } from 'aws-amplify/api';

const onMessagePosted = `
  subscription OnMessagePosted($roomId: ID!) {
    onMessagePosted(roomId: $roomId) {
      id
      text
      user
      createdAt
      roomId
    }
  }
`;

const ChatRoom = ({ roomId }) => {
  const [messages, setMessages] = useState([]);

  useEffect(() => {
    // 初期メッセージの取得
    const fetchInitialMessages = async () => {
      // 上記のfetchMessages関数を使用
      const initialMessages = await fetchMessages(roomId, 50);
      setMessages(initialMessages);
    };

    fetchInitialMessages();

    // リアルタイム購読の開始
    const subscription = graphql({
      query: onMessagePosted,
      variables: { roomId }
    }).subscribe({
      next: ({ data }) => {
        const newMessage = data.onMessagePosted;
        console.log('新着メッセージ:', newMessage);
        
        // 新しいメッセージを既存リストに追加
        setMessages(prevMessages => {
          // 重複チェック
          const exists = prevMessages.some(msg => msg.id === newMessage.id);
          if (exists) return prevMessages;
          
          // 時系列順で挿入
          return [...prevMessages, newMessage].sort(
            (a, b) => new Date(a.createdAt) - new Date(b.createdAt)
          );
        });
      },
      error: (error) => {
        console.error('Subscription エラー:', error);
      }
    });

    // クリーンアップ
    return () => {
      subscription.unsubscribe();
    };
  }, [roomId]);

  return (
    <div>
      <div className="messages">
        {messages.map(message => (
          <div key={message.id} className="message">
            <strong>{message.user}</strong>: {message.text}
            <small>{new Date(message.createdAt).toLocaleString()}</small>
          </div>
        ))}
      </div>
    </div>
  );
};
```

### 2. 新着ルームの購読

**目的**: 新しいルームが作成された時の通知

```graphql
subscription OnRoomCreated {
  onRoomCreated {
    id
    name
    owner
    createdAt
  }
}
```

**実装例**:
```javascript
const onRoomCreated = `
  subscription OnRoomCreated {
    onRoomCreated {
      id
      name
      owner
      createdAt
    }
  }
`;

const useRoomNotifications = () => {
  const [rooms, setRooms] = useState([]);

  useEffect(() => {
    const subscription = graphql({
      query: onRoomCreated
    }).subscribe({
      next: ({ data }) => {
        const newRoom = data.onRoomCreated;
        console.log('新しいルーム:', newRoom);
        
        // 通知表示
        toast.info(`新しいルーム「${newRoom.name}」が作成されました`);
        
        // ルームリストに追加
        setRooms(prevRooms => [newRoom, ...prevRooms]);
      }
    });

    return () => subscription.unsubscribe();
  }, []);

  return { rooms };
};
```

## 🚀 高度なパターン

### 1. バッチ処理での効率化

**複数ルームの情報を一度に取得**:

```javascript
const getMultipleRooms = async (roomIds) => {
  // Promise.allを使って並列処理
  const promises = roomIds.map(id => 
    graphql({
      query: getRoomWithMessages,
      variables: { id }
    })
  );
  
  const results = await Promise.all(promises);
  return results.map(result => result.data.getRoom);
};
```

### 2. エラーハンドリング

**包括的なエラー処理**:

```javascript
const safeGraphQLCall = async (query, variables = {}) => {
  try {
    const result = await graphql({ query, variables });
    return { data: result.data, error: null };
  } catch (error) {
    console.error('GraphQL Error:', error);
    
    // エラーの種類に応じた処理
    if (error.errors) {
      // GraphQLエラー
      const graphqlError = error.errors[0];
      return { 
        data: null, 
        error: graphqlError.message || 'GraphQLエラーが発生しました' 
      };
    } else if (error.message.includes('Network')) {
      // ネットワークエラー
      return { 
        data: null, 
        error: 'ネットワークエラーです。接続を確認してください。' 
      };
    } else {
      // その他のエラー
      return { 
        data: null, 
        error: '予期しないエラーが発生しました' 
      };
    }
  }
};

// 使用例
const { data, error } = await safeGraphQLCall(getMyOwnedRooms);
if (error) {
  alert(error);
} else {
  setRooms(data.myOwnedRooms);
}
```

### 3. キャッシュ戦略

**ローカルキャッシュでパフォーマンス向上**:

```javascript
const cache = new Map();

const cachedGraphQLCall = async (query, variables = {}, cacheKey = null) => {
  const key = cacheKey || `${query}-${JSON.stringify(variables)}`;
  
  // キャッシュヒット
  if (cache.has(key)) {
    console.log('キャッシュから取得:', key);
    return cache.get(key);
  }
  
  // 新規取得
  const result = await graphql({ query, variables });
  cache.set(key, result);
  
  // 5分後にキャッシュ削除
  setTimeout(() => cache.delete(key), 5 * 60 * 1000);
  
  return result;
};
```

## 🔍 デバッグのコツ

### 1. ログ出力

```javascript
const debugGraphQL = async (query, variables) => {
  console.log('📤 GraphQL Request:', { query, variables });
  
  const start = Date.now();
  const result = await graphql({ query, variables });
  const end = Date.now();
  
  console.log('📥 GraphQL Response:', result);
  console.log(`⏱️ 実行時間: ${end - start}ms`);
  
  return result;
};
```

### 2. エラー詳細の表示

```javascript
const handleGraphQLError = (error) => {
  console.error('GraphQL Error Details:', {
    message: error.message,
    errors: error.errors,
    data: error.data,
    extensions: error.extensions
  });
};
```

## 📚 次のステップ

このガイドでGraphQLクエリの実践的な使い方を学んだら、次は以下に進みましょう：

1. **[JavaScript Resolverテンプレート](../templates/javascript-resolver-basic-template.md)** - バックエンド実装
2. **[React GraphQLテンプレート](../templates/react-graphql-template.md)** - フロントエンド統合
3. **[API追加ガイド](./API追加ガイド.md)** - 新機能の追加方法

**🌟 実際にコードを動かしながら学ぶことで、GraphQLの力を実感できます！ 🌟**

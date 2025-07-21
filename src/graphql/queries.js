// =================================================================
// GraphQL クエリ集
// =================================================================
// GraphQLとは、サーバーからデータを取得するための「質問文」を書く言語です
// ここには「データを取得する」ためのクエリ（質問）を書いています
// 
// 例えば「自分が作ったルーム一覧を教えて」「このルームのメッセージを教えて」
// のような質問をGraphQLで書いています

// 自分が作成したルーム一覧を取得するクエリ
// 「myOwnedRooms」という名前で、自分が所有者のルームの情報を聞いています
export const myOwnedRooms = /* GraphQL */ `
  query MyOwnedRooms {
    myOwnedRooms {
      id          # ルームの識別番号
      name        # ルームの名前
      owner       # ルームの作成者
      createdAt   # ルームが作られた日時
    }
  }
`;

// 自分が参加しているルーム一覧を取得するクエリ
// 「myActiveRooms」という名前で、自分が発言したことがあるルームの情報を聞いています
export const myActiveRooms = /* GraphQL */ `
  query MyActiveRooms {
    myActiveRooms {
      id          # ルームの識別番号
      name        # ルームの名前
      owner       # ルームの作成者
      createdAt   # ルームが作られた日時
    }
  }
`;

// 特定のルームの詳細情報を取得するクエリ
// 「getRoom」という名前で、指定したIDのルーム情報を聞いています
// $id: ID! の部分は「IDという変数を必須で受け取る」という意味
export const getRoom = /* GraphQL */ `
  query GetRoom($id: ID!) {
    getRoom(id: $id) {
      id          # ルームの識別番号
      name        # ルームの名前
      owner       # ルームの作成者
      createdAt   # ルームが作られた日時
    }
  }
`;

// 特定のルームのメッセージ一覧を取得するクエリ
// 「listMessages」という名前で、指定したルームのメッセージを聞いています
// $roomId: ID! = ルームIDは必須、$limit: Int = 取得件数は任意
export const listMessages = /* GraphQL */ `
  query ListMessages($roomId: ID!, $limit: Int) {
    listMessages(roomId: $roomId, limit: $limit) {
      id          # メッセージの識別番号
      text        # メッセージの本文
      user        # メッセージを送った人
      createdAt   # メッセージが送られた日時
      roomId      # どのルームのメッセージか
    }
  }
`;

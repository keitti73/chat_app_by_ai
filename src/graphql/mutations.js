// =================================================================
// GraphQL ミューテーション集
// =================================================================
// ミューテーションとは「データを変更する」ためのGraphQL文です
// クエリが「データを読む」なら、ミューテーションは「データを書く・変更する」
// 
// 例えば「新しいルームを作って」「メッセージを投稿して」のような
// サーバーのデータを変更する操作をここに書いています

// 新しいチャットルームを作成するミューテーション
// 「createRoom」という名前で、新しいルームを作成してもらいます
// $name: String! = ルーム名を必須で受け取る
export const createRoom = /* GraphQL */ `
  mutation CreateRoom($name: String!) {
    createRoom(name: $name) {
      id          # 作成されたルームの識別番号
      name        # 作成されたルームの名前
      owner       # 作成されたルームの所有者
      createdAt   # 作成された日時
    }
  }
`;

// 指定したルームにメッセージを投稿するミューテーション
// 「postMessage」という名前で、メッセージを送信してもらいます
// $roomId: ID! = どのルームに送るか（必須）
// $text: String! = メッセージの内容（必須）
export const postMessage = /* GraphQL */ `
  mutation PostMessage($roomId: ID!, $text: String!) {
    postMessage(roomId: $roomId, text: $text) {
      id          # 投稿されたメッセージの識別番号
      text        # 投稿されたメッセージの内容
      user        # 投稿した人の名前
      createdAt   # 投稿された日時
      roomId      # どのルームに投稿されたか
    }
  }
`;

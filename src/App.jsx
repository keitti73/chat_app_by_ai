// =================================================================
// AWS AppSync チャットアプリ メインファイル
// =================================================================
// このファイルはアプリ全体をコントロールする「司令塔」です
// ルーム一覧画面とチャット画面を切り替えたり、
// AWS（Amazon Web Services）との接続設定をしています

// React（画面を作るためのライブラリ）から必要な機能をインポート
import React, { useState } from 'react';
// AWS Amplify（AWSと簡単に接続するためのライブラリ）をインポート
import { Amplify } from 'aws-amplify';
// 自分で作った画面コンポーネントをインポート
import MyRooms from './components/MyRooms';     // ルーム一覧画面
import ChatRoom from './components/ChatRoom';   // チャット画面

// AWS接続設定（環境変数から値を読み込む）
// 環境変数とは、プログラムの外側で設定できる値のことです
// .envファイルに書いた値がここで使われます
const amplifyConfig = {
  // AWSのプロジェクトがある地域（例：日本、アメリカなど）
  aws_project_region: import.meta.env.VITE_AWS_REGION || 'us-east-1',
  // GraphQL API のURL（サーバーと通信するためのアドレス）
  aws_appsync_graphqlEndpoint: import.meta.env.VITE_APPSYNC_GRAPHQL_ENDPOINT || 'https://your-appsync-endpoint.amazonaws.com/graphql',
  // AppSyncサービスがある地域
  aws_appsync_region: import.meta.env.VITE_AWS_REGION || 'us-east-1',
  // 認証方法（今回はAPIキーを使った簡単な方法）
  aws_appsync_authenticationType: import.meta.env.VITE_APPSYNC_AUTH_TYPE || 'API_KEY',
  // APIを使うための鍵（パスワードのようなもの）
  aws_appsync_apiKey: import.meta.env.VITE_APPSYNC_API_KEY || 'your-api-key',
};

// Amplifyライブラリに上で設定した内容を教える
Amplify.configure(amplifyConfig);

// App関数：アプリ全体の動作を決める関数
function App() {
  // 画面の状態を管理する変数
  // 'rooms' = ルーム一覧画面、'chat' = チャット画面
  const [currentView, setCurrentView] = useState('rooms');
  
  // 現在選択されているルームの情報を保存する変数
  // null = 何も選択されていない状態
  const [selectedRoom, setSelectedRoom] = useState(null);
  
  // ユーザー名（今は固定値、将来は本当のログイン機能を追加予定）
  const [username] = useState('demo-user');

  // ルームが選択された時に実行される関数
  const handleRoomSelect = (roomId, roomName) => {
    // 選択されたルームの情報を保存
    setSelectedRoom({ id: roomId, name: roomName });
    // 画面をチャット画面に切り替え
    setCurrentView('chat');
  };

  // 「戻る」ボタンが押された時に実行される関数
  const handleBackToRooms = () => {
    // 画面をルーム一覧に戻す
    setCurrentView('rooms');
    // 選択されたルームの情報をクリア
    setSelectedRoom(null);
  };

  // この関数が返すJSX（見た目の設計図）がブラウザに表示される
  return (
    // アプリ全体を囲む大きな箱
    <div style={{ fontFamily: 'Arial, sans-serif' }}>
      {/* ヘッダー部分（アプリの上部に表示される部分） */}
      <header style={{
        backgroundColor: '#343a40',  // 濃いグレー色
        color: 'white',              // 文字色は白
        padding: '10px 20px',        // 内側の余白
        textAlign: 'center'          // 文字を中央揃え
      }}>
        <h1>AppSync Chat App</h1>
        <small>ユーザー: {username}</small>
      </header>

      {/* メインコンテンツ部分 */}
      <main>
        {/* 
          条件分岐：currentViewの値によって表示する画面を切り替える
          ? と : を使った三項演算子という書き方
          「もし currentView が 'rooms' なら ○○ を表示、そうでなければ ××を表示」
        */}
        {currentView === 'rooms' ? (
          // ルーム一覧画面を表示
          <MyRooms 
            username={username}                 // ユーザー名を渡す
            onRoomSelect={handleRoomSelect}     // ルーム選択時の処理を渡す
          />
        ) : (
          // チャット画面を表示
          <ChatRoom
            roomId={selectedRoom?.id}           // 選択されたルームのID
            roomName={selectedRoom?.name}       // 選択されたルームの名前
            username={username}                 // ユーザー名
            onBack={handleBackToRooms}          // 戻るボタンの処理
          />
        )}
      </main>
    </div>
  );
}

// このApp関数を他のファイルから使えるようにエクスポート（公開）
export default App;

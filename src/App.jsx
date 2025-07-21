// =================================================================
// AWS AppSync チャットアプリ メインファイル（Cognito認証対応版）
// =================================================================
// このファイルはアプリ全体をコントロールする「司令塔」です
// ルーム一覧画面とチャット画面を切り替えたり、
// AWS（Amazon Web Services）との接続設定をしています
// 
// 🆕 新機能：Amazon Cognitoを使った本格的なユーザー認証

// React（画面を作るためのライブラリ）から必要な機能をインポート
import React, { useState, useEffect } from 'react';
// AWS Amplify（AWSと簡単に接続するためのライブラリ）をインポート
import { Amplify } from 'aws-amplify';
import { getCurrentUser, signOut } from 'aws-amplify/auth';
// 自分で作った画面コンポーネントをインポート
import MyRooms from './components/MyRooms';     // ルーム一覧画面
import ChatRoom from './components/ChatRoom';   // チャット画面
import AuthForm from './components/AuthForm';   // 🆕 ログイン・新規登録画面

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
  // 🆕 認証方法（CognitoまたはAPIキー）
  aws_appsync_authenticationType: import.meta.env.VITE_APPSYNC_AUTH_TYPE || 'AMAZON_COGNITO_USER_POOLS',
  
  // 🆕 Cognito認証設定
  aws_cognito_region: import.meta.env.VITE_COGNITO_REGION || import.meta.env.VITE_AWS_REGION || 'us-east-1',
  aws_user_pools_id: import.meta.env.VITE_COGNITO_USER_POOL_ID || 'us-east-1_xxxxxxxxx',
  aws_user_pools_web_client_id: import.meta.env.VITE_COGNITO_USER_POOL_CLIENT_ID || 'xxxxxxxxxxxxxxxxxxxxxxxxxx',
  aws_cognito_identity_pool_id: import.meta.env.VITE_COGNITO_IDENTITY_POOL_ID || 'us-east-1:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
  
  // APIキー（バックアップ用、Cognitoが主）
  aws_appsync_apiKey: import.meta.env.VITE_APPSYNC_API_KEY || 'your-api-key',
};

// Amplifyライブラリに上で設定した内容を教える
Amplify.configure(amplifyConfig);

// App関数：アプリ全体の動作を決める関数
function App() {
  // 🆕 認証状態の管理
  const [isAuthenticated, setIsAuthenticated] = useState(false);  // ログインしているかどうか
  const [currentUser, setCurrentUser] = useState(null);          // 現在のユーザー情報
  const [authLoading, setAuthLoading] = useState(true);          // 認証状態確認中かどうか
  
  // 画面の状態を管理する変数
  // 'rooms' = ルーム一覧画面、'chat' = チャット画面
  const [currentView, setCurrentView] = useState('rooms');
  
  // 現在選択されているルームの情報を保存する変数
  // null = 何も選択されていない状態
  const [selectedRoom, setSelectedRoom] = useState(null);

  // 🆕 アプリ起動時に実行される処理（認証状態の確認）
  useEffect(() => {
    checkAuthState();
  }, []);

  // 🆕 認証状態をチェックする関数
  const checkAuthState = async () => {
    try {
      // 既にログインしているユーザーがいるかチェック
      const user = await getCurrentUser();
      setCurrentUser(user);
      setIsAuthenticated(true);
      console.log('既存ユーザーでログイン:', user.username);
    } catch (error) {
      // ログインしていない場合（エラーは正常）
      console.log('未ログイン状態');
      setIsAuthenticated(false);
      setCurrentUser(null);
    } finally {
      setAuthLoading(false);  // 認証状態の確認完了
    }
  };

  // 🆕 認証成功時の処理
  const handleAuthSuccess = (user) => {
    setCurrentUser(user);
    setIsAuthenticated(true);
    console.log('ログイン成功:', user.username);
  };

  // 🆕 ログアウト処理
  const handleSignOut = async () => {
    try {
      await signOut();
      setCurrentUser(null);
      setIsAuthenticated(false);
      setCurrentView('rooms');  // ルーム一覧に戻す
      setSelectedRoom(null);    // 選択ルームをクリア
      console.log('ログアウト完了');
    } catch (error) {
      console.error('ログアウトエラー:', error);
    }
  };

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

  // 🆕 認証状態確認中の画面
  if (authLoading) {
    return (
      <div style={{ 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center', 
        height: '100vh',
        fontFamily: 'Arial, sans-serif'
      }}>
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontSize: 24, marginBottom: 10 }}>🔄</div>
          <div>認証状態を確認中...</div>
        </div>
      </div>
    );
  }

  // 🆕 未ログイン時はログイン画面を表示
  if (!isAuthenticated) {
    return <AuthForm onAuthSuccess={handleAuthSuccess} />;
  }

  // この関数が返すJSX（見た目の設計図）がブラウザに表示される
  return (
    // アプリ全体を囲む大きな箱
    <div style={{ fontFamily: 'Arial, sans-serif' }}>
      {/* ヘッダー部分（アプリの上部に表示される部分） */}
      <header style={{
        backgroundColor: '#343a40',  // 濃いグレー色
        color: 'white',              // 文字色は白
        padding: '10px 20px',        // 内側の余白
        display: 'flex',             // 🆕 横並びレイアウト
        justifyContent: 'space-between',  // 🆕 左右に分散配置
        alignItems: 'center'         // 🆕 縦方向の中央揃え
      }}>
        <div style={{ textAlign: 'left' }}>
          <h1 style={{ margin: 0 }}>AppSync Chat App</h1>
          {/* 🆕 ユーザー情報表示（Cognitoから取得） */}
          <small>ユーザー: {currentUser?.username || 'Unknown'}</small>
        </div>
        
        {/* 🆕 ログアウトボタン */}
        <button
          onClick={handleSignOut}
          style={{
            backgroundColor: '#dc3545',  // 赤色
            color: 'white',
            border: 'none',
            padding: '8px 16px',
            borderRadius: 4,
            cursor: 'pointer',
            fontSize: 14
          }}
        >
          🚪 ログアウト
        </button>
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
            username={currentUser?.username || 'Unknown'}  // 🆕 Cognitoから取得したユーザー名
            onRoomSelect={handleRoomSelect}               // ルーム選択時の処理を渡す
          />
        ) : (
          // チャット画面を表示
          <ChatRoom
            roomId={selectedRoom?.id}                     // 選択されたルームのID
            roomName={selectedRoom?.name}                 // 選択されたルームの名前
            username={currentUser?.username || 'Unknown'} // 🆕 Cognitoから取得したユーザー名
            onBack={handleBackToRooms}                    // 戻るボタンの処理
          />
        )}
      </main>
    </div>
  );
}

// このApp関数を他のファイルから使えるようにエクスポート（公開）
export default App;

// =================================================================
// 認証コンポーネント（ログイン・ユーザー登録画面）
// =================================================================
// このコンポーネントは、ユーザーのログインと新規登録を担当します
// Amazon Cognitoを使って、安全なユーザー認証を実現しています

import React, { useState } from 'react';
import { signIn, signUp, confirmSignUp, getCurrentUser } from 'aws-amplify/auth';

// AuthFormコンポーネント：ログイン・新規登録フォーム
export default function AuthForm({ onAuthSuccess }) {
  // 画面の状態管理
  const [mode, setMode] = useState('signin');  // 'signin'（ログイン）または 'signup'（新規登録）
  const [loading, setLoading] = useState(false);  // 読み込み中かどうか
  const [message, setMessage] = useState('');  // ユーザーへのメッセージ
  
  // フォームの入力値管理
  const [formData, setFormData] = useState({
    email: '',
    password: '',
    name: '',
    confirmationCode: ''
  });

  // フォームの入力値が変更された時に実行される関数
  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  // ログイン処理
  const handleSignIn = async (e) => {
    e.preventDefault();  // ページのリロードを防ぐ
    setLoading(true);
    setMessage('');

    try {
      // Cognitoにログイン要求を送信
      const user = await signIn({
        username: formData.email,
        password: formData.password
      });

      // ログイン成功時の処理
      setMessage('ログインに成功しました！');
      
      // 現在のユーザー情報を取得
      const currentUser = await getCurrentUser();
      
      // 親コンポーネントに認証成功を通知
      onAuthSuccess(currentUser);
      
    } catch (error) {
      console.error('ログインエラー:', error);
      
      // エラーメッセージを日本語で表示
      switch (error.name) {
        case 'NotAuthorizedException':
          setMessage('メールアドレスまたはパスワードが間違っています。');
          break;
        case 'UserNotConfirmedException':
          setMessage('メールアドレスの確認が完了していません。確認コードを入力してください。');
          setMode('confirm');
          break;
        default:
          setMessage('ログインに失敗しました。しばらく時間をおいて再度お試しください。');
      }
    } finally {
      setLoading(false);
    }
  };

  // 新規登録処理
  const handleSignUp = async (e) => {
    e.preventDefault();
    setLoading(true);
    setMessage('');

    try {
      // Cognitoに新規ユーザー登録要求を送信
      const { isSignUpComplete, userId, nextStep } = await signUp({
        username: formData.email,
        password: formData.password,
        options: {
          userAttributes: {
            email: formData.email,
            name: formData.name
          }
        }
      });

      if (nextStep.signUpStep === 'CONFIRM_SIGN_UP') {
        setMessage('確認コードをメールアドレスに送信しました。コードを入力してアカウントを有効化してください。');
        setMode('confirm');
      }
      
    } catch (error) {
      console.error('新規登録エラー:', error);
      
      // エラーメッセージを日本語で表示
      switch (error.name) {
        case 'UsernameExistsException':
          setMessage('このメールアドレスは既に登録されています。');
          break;
        case 'InvalidPasswordException':
          setMessage('パスワードは8文字以上で、大文字・小文字・数字を含む必要があります。');
          break;
        default:
          setMessage('新規登録に失敗しました。入力内容をご確認ください。');
      }
    } finally {
      setLoading(false);
    }
  };

  // 確認コード送信処理
  const handleConfirmSignUp = async (e) => {
    e.preventDefault();
    setLoading(true);
    setMessage('');

    try {
      // 確認コードをCognitoに送信
      const { isSignUpComplete } = await confirmSignUp({
        username: formData.email,
        confirmationCode: formData.confirmationCode
      });

      if (isSignUpComplete) {
        setMessage('アカウントの確認が完了しました！ログインしてください。');
        setMode('signin');
        // フォームをクリア
        setFormData({
          email: formData.email,  // メールアドレスは残す
          password: '',
          name: '',
          confirmationCode: ''
        });
      }
      
    } catch (error) {
      console.error('確認エラー:', error);
      
      switch (error.name) {
        case 'CodeMismatchException':
          setMessage('確認コードが間違っています。');
          break;
        case 'ExpiredCodeException':
          setMessage('確認コードの有効期限が切れています。');
          break;
        default:
          setMessage('確認に失敗しました。コードをご確認ください。');
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{
      maxWidth: 400,
      margin: '50px auto',
      padding: 30,
      border: '1px solid #ddd',
      borderRadius: 10,
      backgroundColor: '#fff',
      boxShadow: '0 2px 10px rgba(0,0,0,0.1)'
    }}>
      <h2 style={{ textAlign: 'center', marginBottom: 30 }}>
        {mode === 'signin' && '📧 ログイン'}
        {mode === 'signup' && '🆕 新規登録'}
        {mode === 'confirm' && '✅ アカウント確認'}
      </h2>

      {/* メッセージ表示 */}
      {message && (
        <div style={{
          padding: 10,
          marginBottom: 20,
          borderRadius: 5,
          backgroundColor: message.includes('成功') || message.includes('完了') ? '#d4edda' : '#f8d7da',
          color: message.includes('成功') || message.includes('完了') ? '#155724' : '#721c24',
          border: `1px solid ${message.includes('成功') || message.includes('完了') ? '#c3e6cb' : '#f5c6cb'}`
        }}>
          {message}
        </div>
      )}

      {/* ログインフォーム */}
      {mode === 'signin' && (
        <form onSubmit={handleSignIn}>
          <div style={{ marginBottom: 15 }}>
            <label style={{ display: 'block', marginBottom: 5 }}>メールアドレス</label>
            <input
              type="email"
              name="email"
              value={formData.email}
              onChange={handleInputChange}
              required
              style={{
                width: '100%',
                padding: 10,
                border: '1px solid #ccc',
                borderRadius: 5,
                fontSize: 16
              }}
            />
          </div>
          <div style={{ marginBottom: 20 }}>
            <label style={{ display: 'block', marginBottom: 5 }}>パスワード</label>
            <input
              type="password"
              name="password"
              value={formData.password}
              onChange={handleInputChange}
              required
              style={{
                width: '100%',
                padding: 10,
                border: '1px solid #ccc',
                borderRadius: 5,
                fontSize: 16
              }}
            />
          </div>
          <button
            type="submit"
            disabled={loading}
            style={{
              width: '100%',
              padding: 12,
              backgroundColor: '#007bff',
              color: 'white',
              border: 'none',
              borderRadius: 5,
              fontSize: 16,
              cursor: loading ? 'not-allowed' : 'pointer'
            }}
          >
            {loading ? 'ログイン中...' : 'ログイン'}
          </button>
          
          <p style={{ textAlign: 'center', marginTop: 20 }}>
            アカウントをお持ちでない方は{' '}
            <button
              type="button"
              onClick={() => setMode('signup')}
              style={{
                background: 'none',
                border: 'none',
                color: '#007bff',
                textDecoration: 'underline',
                cursor: 'pointer'
              }}
            >
              新規登録
            </button>
          </p>
        </form>
      )}

      {/* 新規登録フォーム */}
      {mode === 'signup' && (
        <form onSubmit={handleSignUp}>
          <div style={{ marginBottom: 15 }}>
            <label style={{ display: 'block', marginBottom: 5 }}>お名前</label>
            <input
              type="text"
              name="name"
              value={formData.name}
              onChange={handleInputChange}
              required
              style={{
                width: '100%',
                padding: 10,
                border: '1px solid #ccc',
                borderRadius: 5,
                fontSize: 16
              }}
            />
          </div>
          <div style={{ marginBottom: 15 }}>
            <label style={{ display: 'block', marginBottom: 5 }}>メールアドレス</label>
            <input
              type="email"
              name="email"
              value={formData.email}
              onChange={handleInputChange}
              required
              style={{
                width: '100%',
                padding: 10,
                border: '1px solid #ccc',
                borderRadius: 5,
                fontSize: 16
              }}
            />
          </div>
          <div style={{ marginBottom: 20 }}>
            <label style={{ display: 'block', marginBottom: 5 }}>
              パスワード
              <small style={{ display: 'block', color: '#666' }}>
                8文字以上、大文字・小文字・数字を含む
              </small>
            </label>
            <input
              type="password"
              name="password"
              value={formData.password}
              onChange={handleInputChange}
              required
              style={{
                width: '100%',
                padding: 10,
                border: '1px solid #ccc',
                borderRadius: 5,
                fontSize: 16
              }}
            />
          </div>
          <button
            type="submit"
            disabled={loading}
            style={{
              width: '100%',
              padding: 12,
              backgroundColor: '#28a745',
              color: 'white',
              border: 'none',
              borderRadius: 5,
              fontSize: 16,
              cursor: loading ? 'not-allowed' : 'pointer'
            }}
          >
            {loading ? '登録中...' : '新規登録'}
          </button>
          
          <p style={{ textAlign: 'center', marginTop: 20 }}>
            既にアカウントをお持ちの方は{' '}
            <button
              type="button"
              onClick={() => setMode('signin')}
              style={{
                background: 'none',
                border: 'none',
                color: '#007bff',
                textDecoration: 'underline',
                cursor: 'pointer'
              }}
            >
              ログイン
            </button>
          </p>
        </form>
      )}

      {/* 確認コード入力フォーム */}
      {mode === 'confirm' && (
        <form onSubmit={handleConfirmSignUp}>
          <div style={{ marginBottom: 15 }}>
            <label style={{ display: 'block', marginBottom: 5 }}>
              確認コード
              <small style={{ display: 'block', color: '#666' }}>
                {formData.email} に送信されたコードを入力してください
              </small>
            </label>
            <input
              type="text"
              name="confirmationCode"
              value={formData.confirmationCode}
              onChange={handleInputChange}
              required
              style={{
                width: '100%',
                padding: 10,
                border: '1px solid #ccc',
                borderRadius: 5,
                fontSize: 16
              }}
            />
          </div>
          <button
            type="submit"
            disabled={loading}
            style={{
              width: '100%',
              padding: 12,
              backgroundColor: '#17a2b8',
              color: 'white',
              border: 'none',
              borderRadius: 5,
              fontSize: 16,
              cursor: loading ? 'not-allowed' : 'pointer'
            }}
          >
            {loading ? '確認中...' : 'アカウントを確認'}
          </button>
          
          <p style={{ textAlign: 'center', marginTop: 20 }}>
            <button
              type="button"
              onClick={() => setMode('signin')}
              style={{
                background: 'none',
                border: 'none',
                color: '#007bff',
                textDecoration: 'underline',
                cursor: 'pointer'
              }}
            >
              ログインに戻る
            </button>
          </p>
        </form>
      )}
    </div>
  );
}

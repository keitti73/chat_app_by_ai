import React, { useEffect, useState, useRef } from 'react';
import { generateClient } from 'aws-amplify/api';
import { listMessages } from '../graphql/queries';
import { postMessage, analyzeMessageSentimentMutation } from '../graphql/mutations';
import { onMessagePosted } from '../graphql/subscriptions';

const client = generateClient();

export default function ChatRoom({ roomId, roomName, username, onBack }) {
  const [messages, setMessages] = useState([]);
  const [newMessage, setNewMessage] = useState('');
  const [loading, setLoading] = useState(false);
  const [sentimentAnalysis, setSentimentAnalysis] = useState({});
  const [analyzingMessages, setAnalyzingMessages] = useState(new Set());
  const messagesEndRef = useRef(null);

  useEffect(() => {
    if (!roomId) return;
    
    const loadMessages = async () => {
      try {
        const result = await client.graphql({
          query: listMessages,
          variables: { roomId, limit: 100 }
        });
        setMessages(result.data.listMessages || []);
      } catch (error) {
        console.error('Error loading messages:', error);
      }
    };

    loadMessages();
    
    // リアルタイムメッセージ受信
    const subscription = client.graphql({
      query: onMessagePosted,
      variables: { roomId }
    }).subscribe({
      next: ({ data }) => {
        if (data.onMessagePosted) {
          setMessages(prev => [...prev, data.onMessagePosted]);
        }
      },
      error: (err) => console.error('Message subscription error:', err)
    });

    return () => subscription.unsubscribe();
  }, [roomId]);

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const handleSendMessage = async (e) => {
    e.preventDefault();
    if (!newMessage.trim() || loading) return;

    setLoading(true);
    try {
      await client.graphql({
        query: postMessage,
        variables: {
          roomId,
          text: newMessage.trim()
        }
      });
      setNewMessage('');
    } catch (error) {
      console.error('Error sending message:', error);
      alert('メッセージの送信に失敗しました');
    } finally {
      setLoading(false);
    }
  };

  // 🤖 AI感情分析を実行する関数
  const handleAnalyzeSentiment = async (messageId, messageText) => {
    if (analyzingMessages.has(messageId)) return;
    
    setAnalyzingMessages(prev => new Set([...prev, messageId]));
    
    try {
      const result = await client.graphql({
        query: analyzeMessageSentimentMutation,
        variables: {
          messageId,
          text: messageText
        }
      });
      
      setSentimentAnalysis(prev => ({
        ...prev,
        [messageId]: result.data.analyzeMessageSentiment
      }));
    } catch (error) {
      console.error('感情分析エラー:', error);
      alert('感情分析に失敗しました。もう一度お試しください。');
    } finally {
      setAnalyzingMessages(prev => {
        const newSet = new Set(prev);
        newSet.delete(messageId);
        return newSet;
      });
    }
  };

  // 感情スコアに基づいて表示色を決定
  const getSentimentColor = (sentiment) => {
    switch (sentiment) {
      case 'POSITIVE': return '#10b981'; // green-500
      case 'NEGATIVE': return '#ef4444'; // red-500  
      case 'NEUTRAL': return '#6b7280';  // gray-500
      case 'MIXED': return '#f59e0b';    // amber-500
      default: return '#6b7280';
    }
  };

  // 感情を日本語で表示
  const getSentimentLabel = (sentiment) => {
    switch (sentiment) {
      case 'POSITIVE': return 'ポジティブ';
      case 'NEGATIVE': return 'ネガティブ';
      case 'NEUTRAL': return '中立';
      case 'MIXED': return '混合';
      default: return '不明';
    }
  };

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  return (
    <div style={{ maxWidth: 800, margin: "0 auto", padding: 20, height: '80vh', display: 'flex', flexDirection: 'column' }}>
      {/* ヘッダー */}
      <div style={{ borderBottom: '1px solid #ccc', paddingBottom: 10, marginBottom: 20 }}>
        <button onClick={onBack} style={{ marginRight: 10, padding: '5px 10px' }}>
          ← 戻る
        </button>
        <h3 style={{ display: 'inline', margin: 0 }}>
          {roomName} ({roomId})
        </h3>
      </div>

      {/* メッセージ一覧 */}
      <div style={{
        flex: 1,
        overflowY: 'auto',
        border: '1px solid #ccc',
        borderRadius: 8,
        padding: 15,
        marginBottom: 15,
        backgroundColor: '#f9f9f9'
      }}>
        {messages.length === 0 && <div>まだメッセージがありません。</div>}
        {messages.map((message, index) => (
          <div
            key={message.id || index}
            style={{
              marginBottom: 15,
              padding: 10,
              backgroundColor: message.user === username ? '#e3f2fd' : '#fff',
              borderRadius: 8,
              border: '1px solid #ddd'
            }}
          >
            <div style={{ fontWeight: 'bold', marginBottom: 5 }}>
              {message.user}
              <small style={{ marginLeft: 10, color: '#666' }}>
                {new Date(message.createdAt).toLocaleString()}
              </small>
            </div>
            <div style={{ marginBottom: 10 }}>{message.text}</div>
            
            {/* 🤖 AI感情分析セクション */}
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginTop: 8 }}>
              <button
                onClick={() => handleAnalyzeSentiment(message.id, message.text)}
                disabled={analyzingMessages.has(message.id)}
                style={{
                  padding: '4px 8px',
                  fontSize: '12px',
                  backgroundColor: '#6366f1',
                  color: 'white',
                  border: 'none',
                  borderRadius: 4,
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  gap: 4
                }}
              >
                🤖 {analyzingMessages.has(message.id) ? '分析中...' : '感情分析'}
              </button>
              
              {/* 感情分析結果の表示 */}
              {sentimentAnalysis[message.id] && (
                <div style={{ 
                  display: 'flex', 
                  alignItems: 'center', 
                  gap: 8,
                  padding: '4px 8px',
                  backgroundColor: '#f3f4f6',
                  borderRadius: 4,
                  fontSize: '12px'
                }}>
                  <div style={{ 
                    display: 'flex', 
                    alignItems: 'center', 
                    gap: 4,
                    color: getSentimentColor(sentimentAnalysis[message.id].sentiment)
                  }}>
                    <span>😊</span>
                    <span>{getSentimentLabel(sentimentAnalysis[message.id].sentiment)}</span>
                    <span>({Math.round(sentimentAnalysis[message.id].sentimentScore[sentimentAnalysis[message.id].sentiment.toLowerCase()] * 100)}%)</span>
                  </div>
                  
                  {sentimentAnalysis[message.id].language && (
                    <div style={{ color: '#6b7280' }}>
                      📝 {sentimentAnalysis[message.id].language.toUpperCase()}
                    </div>
                  )}
                  
                  {!sentimentAnalysis[message.id].isAppropriate && (
                    <div style={{ color: '#ef4444' }}>
                      ⚠️ 要注意
                    </div>
                  )}
                </div>
              )}
            </div>
          </div>
        ))}
        <div ref={messagesEndRef} />
      </div>

      {/* メッセージ入力 */}
      <form onSubmit={handleSendMessage}>
        <div style={{ display: 'flex', gap: 10 }}>
          <input
            type="text"
            value={newMessage}
            onChange={(e) => setNewMessage(e.target.value)}
            placeholder="メッセージを入力..."
            style={{
              flex: 1,
              padding: 10,
              border: '1px solid #ccc',
              borderRadius: 4,
              fontSize: 14
            }}
            maxLength={500}
          />
          <button
            type="submit"
            disabled={loading || !newMessage.trim()}
            style={{
              padding: '10px 20px',
              backgroundColor: '#28a745',
              color: 'white',
              border: 'none',
              borderRadius: 4,
              cursor: 'pointer'
            }}
          >
            {loading ? '送信中...' : '送信'}
          </button>
        </div>
      </form>
    </div>
  );
}

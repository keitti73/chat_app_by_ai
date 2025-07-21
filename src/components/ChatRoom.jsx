import React, { useEffect, useState, useRef } from 'react';
import { generateClient } from 'aws-amplify/api';
import { listMessages } from '../graphql/queries';
import { postMessage } from '../graphql/mutations';
import { onMessagePosted } from '../graphql/subscriptions';

const client = generateClient();

export default function ChatRoom({ roomId, roomName, username, onBack }) {
  const [messages, setMessages] = useState([]);
  const [newMessage, setNewMessage] = useState('');
  const [loading, setLoading] = useState(false);
  const messagesEndRef = useRef(null);

  useEffect(() => {
    if (!roomId) return;
    
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
            <div>{message.text}</div>
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

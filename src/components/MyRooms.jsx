import React, { useEffect, useState } from 'react';
import { generateClient } from 'aws-amplify/api';
import { myOwnedRooms, myActiveRooms } from '../graphql/queries';
import { createRoom } from '../graphql/mutations';
import { onRoomCreated } from '../graphql/subscriptions';

const client = generateClient();

export default function MyRooms({ username, onRoomSelect }) {
  const [ownedRooms, setOwnedRooms] = useState([]);
  const [activeRooms, setActiveRooms] = useState([]);
  const [newRoomName, setNewRoomName] = useState('');
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    loadRooms();
    
    // リアルタイム新規ルーム通知
    const subscription = client.graphql({ query: onRoomCreated }).subscribe({
      next: ({ data }) => {
        if (data.onRoomCreated) {
          setOwnedRooms(prev => [data.onRoomCreated, ...prev]);
        }
      },
      error: (err) => console.error('Subscription error:', err)
    });

    return () => subscription.unsubscribe();
  }, []);

  const loadRooms = async () => {
    try {
      const [ownedResult, activeResult] = await Promise.all([
        client.graphql({ query: myOwnedRooms }),
        client.graphql({ query: myActiveRooms })
      ]);
      
      setOwnedRooms(ownedResult.data.myOwnedRooms || []);
      setActiveRooms(activeResult.data.myActiveRooms || []);
    } catch (error) {
      console.error('Error loading rooms:', error);
    }
  };

  const handleCreateRoom = async (e) => {
    e.preventDefault();
    if (!newRoomName.trim() || loading) return;

    setLoading(true);
    try {
      await client.graphql({
        query: createRoom,
        variables: { name: newRoomName.trim() }
      });
      setNewRoomName('');
    } catch (error) {
      console.error('Error creating room:', error);
      alert('ルーム作成に失敗しました');
    } finally {
      setLoading(false);
    }
  };

  const allRooms = [
    ...ownedRooms,
    ...activeRooms.filter(r => !ownedRooms.some(or => or.id === r.id))
  ];

  return (
    <div style={{ maxWidth: 480, margin: "0 auto", padding: 20 }}>
      <h3>チャットルーム一覧</h3>
      
      {/* 新規ルーム作成 */}
      <form onSubmit={handleCreateRoom} style={{ marginBottom: 20 }}>
        <div style={{ display: 'flex', gap: 10 }}>
          <input
            type="text"
            value={newRoomName}
            onChange={(e) => setNewRoomName(e.target.value)}
            placeholder="新しいルーム名"
            style={{
              flex: 1,
              padding: 8,
              border: '1px solid #ccc',
              borderRadius: 4
            }}
          />
          <button
            type="submit"
            disabled={loading || !newRoomName.trim()}
            style={{
              padding: '8px 16px',
              backgroundColor: '#007bff',
              color: 'white',
              border: 'none',
              borderRadius: 4,
              cursor: 'pointer'
            }}
          >
            {loading ? '作成中...' : '作成'}
          </button>
        </div>
      </form>

      {/* ルーム一覧 */}
      {allRooms.length === 0 && <div>参加したルームはありません。</div>}
      <ul style={{ listStyle: 'none', padding: 0 }}>
        {allRooms.map(room => (
          <li key={room.id} style={{ marginBottom: 6 }}>
            <button
              style={{
                background: "#fafafa",
                border: "1px solid #ccc",
                padding: 12,
                borderRadius: 8,
                width: "100%",
                textAlign: "left",
                cursor: "pointer"
              }}
              onClick={() => onRoomSelect(room.id, room.name)}
            >
              <b>{room.name}</b> <br />
              <small>
                ルームID: {room.id} <br />
                作成者: {room.owner} <br />
                作成日: {new Date(room.createdAt).toLocaleString()}
              </small>
            </button>
          </li>
        ))}
      </ul>
    </div>
  );
}
